#!/usr/bin/env ruby

# EntityClass
class ActionItem
	attr_accessor :action_id, :tick, :cur_x, :cur_y, :tar_x, :tar_y, :scale, :hit, :radius, :tar_id

	def initialize content
		@action_id, @tick, @cur_x, @cur_y, @tar_x, @tar_y, @scale, dummy, dummy, @hit, @radius, @tar_id = content.split("\t")
		@cur_x = @cur_x.to_f
		@cur_y = @cur_y.to_f
		@tar_x = @tar_x.to_f
		@tar_y = @tar_y.to_f
		@scale = @scale.to_f
		@radius = @radius.to_f
		@hit = (@hit.to_i == 1)
		@tar_id = @tar_id.to_i
		@tick = @tick.to_i
	end
end