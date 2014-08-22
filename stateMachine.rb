#!/usr/bin/env ruby
require_relative './actionItem.rb'

class StateMachine
	attr_accessor :lastLine
	attr_accessor :state, :sensorFirst
	attr_accessor :sensorTime, :sensorStartTime, :sensorEndTime, :touchTime, :touchStartTime, :touchEndTime
	def initialize sensorFirst
		@state = :startOfData
		@sensorFirst = sensorFirst
	end

	def feed line, &block
		item = ActionItem.new line
		if @state == :startOfData
			if @sensorFirst
				if item.scale == -100
					@sensorStartTime = item.tick.to_i
					@state = :sensorWorking
				end
			else
				if item.scale == 100
					@touchStartTime = item.tick.to_i
					@state = :touchWorking
				end
			end
		elsif @state == :sensorWorking
			if @sensorFirst
				if item.scale == -300
					@sensorEndTime = item.tick.to_i
					if @sensorFirst
						@state = :touchBegin
					end
					@state = :touchBegin
				end	
			else
				if item.scale == 100
					@sensorEndTime = item.tick.to_i
					done(@sensorEndTime - @sensorStartTime, @touchEndTime - @touchStartTime, &block)

					@touchStartTime = item.tick.to_i
					@state = :touchWorking
				end
			end
		elsif @state == :touchBegin
			if item.scale == 100
				@state = :touchWorking
				@touchStartTime = item.tick.to_i
			end
		elsif @state == :touchWorking
			if @sensorFirst
				if item.scale == -100
					@touchEndTime = item.tick.to_i
					done(@sensorEndTime - @sensorStartTime, @touchEndTime - @touchStartTime, &block)

					@sensorStartTime = item.tick.to_i
					@state = :sensorWorking
				end
			else
				if item.scale == -100
					@touchEndTime = item.tick.to_i
					@sensorStartTime = item.tick.to_i
					@state = :sensorWorking
				end
			end
		end
	end

	def done sensorTime, touchTime, &block
		if block
			block.call(sensorTime, touchTime)
		end
	end
end