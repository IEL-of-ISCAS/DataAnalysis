#!/usr/bin/env ruby
require_relative './actionItem.rb'

class Parser
	attr_accessor :targets
	attr_accessor :sensorFirst
	attr_accessor :sensorStartPoint, :touchStartPoint
	attr_accessor :sensorTime, :touchTime, :sensorDistance, :touchDistance
	attr_accessor :curIndex, :lastTarId
	attr_accessor :sensorStartTime, :sensorEndTime, :touchStartTime, :touchEndTime

	def initialize sensorFirst
		@sensorFirst = sensorFirst
		@targets = []
		@curIndex = -1
		@lastTarId = -1
	end

	def feed line
		item = ActionItem.new line
		@targets << item
	end

	def parse
		@sensorTime     = []
		@touchTime      = []
		@sensorDistance = []
		@touchDistance  = []
		@sensorWsqr     = []
		@touchWsqr      = []

		result = []
		curTarId = 0

		# Separate into groups
		curSec = []
		@targets.each do |item|
			if curTarId != item.tar_id
				result.push(Array.new(curSec))
				curTarId = item.tar_id

				curSec.clear
			end

			curSec << item
		end

		@targets = result

		@targets.each_with_index do |section, sectionIdx|
			state = :startOfSection
			@touchStartPoint = nil
			@sensorStartPoint = nil

			# For each group, calculate 2 different values
			section.each do |item|
				if @sensorFirst
					if state == :startOfSection
						if item.scale == -100
							break if sectionIdx == 0
							@sensorStartTime = item.tick.to_i
							@sensorStartPoint = [item.cur_x, item.cur_y]
							state = :sensorWorking
						end
					elsif state == :sensorWorking
						if item.scale == -300
							@sensorEndTime = item.tick.to_i
							state = :touchBegin

							diffX = @sensorStartPoint[0] - item.cur_x
							diffY = @sensorStartPoint[1] - item.cur_y
							@sensorDistance << Math.sqrt(diffX * diffX + diffY * diffY)

							diffX = item.cur_x - item.tar_x
							diffY = item.cur_y - item.tar_y
							@sensorWsqr << (diffX * diffX + diffY * diffY)
						end
					elsif state == :touchBegin
						if item.scale == 100
							@touchStartTime = item.tick.to_i
							@touchStartPoint = [item.cur_x, item.cur_y]
							break
						end
					end
				else
					if state == :startOfSection
						if item.scale == 100
							diffX = item.cur_x - item.tar_x
							diffY = item.cur_y - item.tar_y
							@touchStartTime = item.tick.to_i
							@touchDistance << Math.sqrt(diffX * diffX + diffY * diffY)


							state = :touchWorking
						end
					elsif state == :touchWorking
						if item.scale == -100
							@touchEndTime = item.tick.to_i

							diffX = item.cur_x - item.tar_x
							diffY = item.cur_y - item.tar_y
							@sensorDistance << Math.sqrt(diffX * diffX + diffY * diffY)
							@sensorStartTime = item.tick.to_i
							break
						end
					end
				end
			end

			next unless @sensorStartPoint != nil

			section.reverse.each do |item|
				if item.hit and item.tar_id == (sectionIdx % 25)
					if @sensorFirst
						@touchEndTime = item.tick.to_i	

						diffX = item.cur_x - @touchStartPoint[0]
						diffY = item.cur_y - @touchStartPoint[1]
						@touchDistance << Math.sqrt(diffX * diffX + diffY * diffY)

						diffX = item.cur_x - item.tar_x
						diffY = item.cur_y - item.tar_y
						@touchWsqr << (diffX * diffX + diffY * diffY)
					else
						@sensorEndTime = item.tick.to_i
					end
					break
				end
			end

			@sensorTime << @sensorEndTime - @sensorStartTime
			@touchTime  << @touchEndTime  - @touchStartTime
		end

		[@sensorTime, @sensorDistance, @sensorWsqr, @touchTime, @touchDistance, @touchWsqr]
	end
end