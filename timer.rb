#!/usr/bin/env ruby
require 'optparse'
require_relative './parser.rb'

# 计算每组点用户耗时
# 每个点有两个阶段——传感器阶段或触摸屏阶段
# 输入参数为目标数据文件、传感器在先还是触摸屏在先
# 输出每个点两个阶段的耗时情况
# timer.rb -first_phase [touch|sensor] -input datafile.txt

class Timer
	attr_accessor :inputPath
	attr_accessor :sensorFirst
	attr_accessor :outputPath
	attr_accessor :sensorTime
	attr_accessor :touchTime
	attr_accessor :distance

	def initialize inputPath, sensorFirst
		@inputPath = inputPath
		@sensorFirst = sensorFirst
		@outputPath = inputPath.sub(".txt", "time.txt")
		
		@sensorTime = []
		@touchTime = []
		@distance = []
	end

	def process
		parser = Parser.new @sensorFirst
		File.open(@inputPath).each do |line|
			parser.feed line
		end

		sensorTime, sensorDistance, touchTime, touchDistance = parser.parse

		File.open(@outputPath, 'w') do |file|
			file.write("#{sensorTime.join(",")}\n")
			file.write("#{sensorDistance.join(",")}\n")
			file.write("#{touchTime.join(",")}\n")
			file.write("#{touchDistance.join(",")}\n")
		end
	end
end

opt_parser = OptionParser.new do |opts|
	opts.banner = "Usage: timer.rb --first_phase [touch|sensor] --input datafile.txt --output outfile.txt"

	opts.separator ""
	opts.separator "Specific options:"

	opts.on("-f", "--first_phase [first phase]",
	    	"Choose first phase in the experiment") do |fp|
		@sensorFirst = (fp == "sensor")
	end

	opts.on("-i", "--input [input file]",
	    	"Input file path") do |inputPath|
		@inputPath = inputPath
	end
end

opt_parser.parse!(ARGV)
t = Timer.new @inputPath, @sensorFirst
t.process