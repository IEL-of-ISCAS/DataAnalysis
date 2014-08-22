#!/usr/bin/env ruby
require_relative './actionItem.rb'

class Parser
	attr_accessor :targets
	attr_accessor :sensorFirst
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
		@sensorTime = []
		@touchTime = []
		@sensorDistance = []
		@touchDistance = []

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

			# For each group, calculate 2 different values
			section.each do |item|
				if @sensorFirst
					if state == :startOfSection
						if item.scale == -100
							if sectionIdx > 0
								lastItem = nil
								lastSection = @targets[sectionIdx - 1]
								lastSection.reverse.each do |item|
									if item.hit
										lastItem = item
									end
								end
								
								if !lastItem
									break
								end
								diffX = lastItem.cur_x - item.tar_x
								diffY = lastItem.cur_y - item.tar_y
							else
								diffX = item.cur_x - item.tar_x
								diffY = item.cur_y - item.tar_y
							end

							@sensorStartTime = item.tick.to_i
							@sensorDistance << Math.sqrt(diffX * diffX + diffY * diffY)
							state = :sensorWorking
						end
					elsif state == :sensorWorking
						if item.scale == -300
							@sensorEndTime = item.tick.to_i
							state = :touchBegin
						end
					elsif state == :touchBegin
						if item.scale == 100
							@touchStartTime = item.tick.to_i
							diffX = item.cur_x - item.tar_x
							diffY = item.cur_y - item.tar_y
							@touchDistance << Math.sqrt(diffX * diffX + diffY * diffY)
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

			section.reverse.each do |item|
				if item.hit
					if @sensorFirst
						@touchEndTime = item.tick.to_i	
					else
						@sensorEndTime = item.tick.to_i
					end
					break
				end
			end

			@sensorTime << @sensorEndTime - @sensorStartTime
			@touchTime  << @touchEndTime  - @touchStartTime
		end

		[@sensorTime, @sensorDistance, @touchTime, @touchDistance]
	end
end