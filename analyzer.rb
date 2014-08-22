#!/usr/bin/env ruby
require './actionItem.rb'

# 指针悬停位置均值的方差
# 用户调整size的平均值
# 从哪里开始粗定位转细定位
def distance(a, b)
	(b[0] - a[0]) ** 2 + (b[1] - a[1]) ** 2
end

def calcCovirance(avg, data)
	sum = 0
	data.each {|d| sum += distance(avg, d)}
	sum.to_f / data.length
end

def calcAvg(hover_points)
	sum_point = hover_points.inject {|sum, value| [sum[0] + value[0], sum[1] + value[1]]}
	[sum_point[0] / hover_points.length, sum_point[1] / hover_points.length]
end


sum_scale = 0
ARGV.each do |filename|
	last_tar_id = -1
	groups = []
	cur_group = []
	hover_points = []
	scales = []
	transition = []

	File.open(filename) do |f|
		f.each_line do |line|
			item = ActionItem.new line
			if item.tar_id != last_tar_id
				last_tar_id = item.tar_id
				cur_group = [item]
				groups << cur_group
			else
				cur_group << item
			end
		end
	end

	if groups.length == 0
		next
	end

	type = filename.split("_")[-1][0..-5]
	radius = groups[0][0].radius
	valid_groups = groups.slice(1, 25)
	if valid_groups.length == 0
		next
	end

	sensor_ticks = 0
	touch_ticks = 0
	last_tick = 0
	total_ticks = valid_groups[-1][-1].tick.to_i - groups[0][-1].tick.to_i
	error_count = 0
	total_count = 0

	last_scale = 0
	groups[0].each do |action|
		if action.scale > -100 and action.scale < 100 and action.scale != 0
			last_scale = action.scale
		end
	end
	scales << last_scale

	last_group = groups[0]
	last_action = last_group[-1].action_id
	last_tick = last_group[-1].tick.to_i

	valid_groups.each do |group|
		last_scale = 0
		group.each do |action|
			if action.action_id != last_action
				tick_diff = action.tick.to_i - last_tick
				sensor_ticks += tick_diff if last_action == "1"
				touch_ticks += tick_diff if last_action == "2"
				last_action = action.action_id
				last_tick = action.tick.to_i
			end

			if action.scale > -100 and action.scale < 100 and action.scale != 0
				last_scale = action.scale
			end

			scales << last_scale if last_scale != 0
		end

		detail_control_type = group[0].action_id
		detail_actions = []
		start_reading = false
		got_detail_actions = false
		group.reverse.each do |action|
			if !start_reading and action.action_id == detail_control_type
				detail_actions << action
				start_reading = true
			elsif start_reading and !got_detail_actions and action.action_id == detail_control_type
				detail_actions << action
			elsif start_reading and action.action_id != detail_control_type
				got_detail_actions = true
			end
		end
		detail_actions.reverse!

		trans_action = detail_actions[0]
		transition << [trans_action.tar_x - trans_action.cur_x, trans_action.tar_y - trans_action.cur_y]

		cur_hover_points = []
		hit_detail_actions = detail_actions.select {|action| action.hit}
		total_count += hit_detail_actions.length
		hit_detail_actions.each do |action|
			x = action.tar_x - action.cur_x
			y = action.tar_y - action.cur_y
			cur_hover_points << [x, y]
		end
		# detail_actions.each do |action|
		# 	if action.hit
		# 		x = action.tar_x - action.cur_x
		# 		y = action.tar_y - action.cur_y
		# 		cur_hover_points << [x, y]
		# 	end
		# end

		if !cur_hover_points || cur_hover_points.length == 0
			next
		end

		avg = calcAvg(cur_hover_points)
		cov = calcCovirance(avg, cur_hover_points)
		std_dev = Math.sqrt(cov)
		error_count += hit_detail_actions.select {|action| (3 * std_dev) < Math.sqrt(distance([action.tar_x, action.tar_y], [action.cur_x, action.cur_y]))}.length

		hover_points << [avg, cov]
	end

	if last_tick != valid_groups[-1][-1].tick.to_i
		tick_diff = valid_groups[-1][-1].tick.to_i - last_tick
		sensor_ticks += tick_diff if last_action == "1"
		touch_ticks += tick_diff if last_action == "2"
	end

	avg_scale = scales.inject {|sum, value| sum + value} / scales.length
	sum_transition = 0
	transition.each do |trans|
		sum_transition += Math.sqrt(trans[0] ** 2 + trans[1] ** 2)
	end
	avg_transition = sum_transition / transition.length

	sum_scale += avg_scale
	avg_point, avg_cov = hover_points.inject {|sum, value| [[sum[0][0] + value[0][0], sum[0][1] + value[0][1]], sum[1] + value[1]]}

	puts "#{type}\t#{total_ticks}\t#{sensor_ticks}\t#{touch_ticks}\t#{valid_groups.length}\t#{total_ticks * 1.0 / valid_groups.length}\t#{avg_scale}\t#{radius}"#\t#{avg_transition}\t#{avg_transition / radius}"#\t#{avg_point[0]}\t#{avg_point[1]}\t#{avg_cov}"
end
