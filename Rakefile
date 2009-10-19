
require 'rubygems'
gem 'treetop'
require 'echoe'

require 'spec/rake/spectask'

Echoe.new("configgy") do |p|
  p.version = "0.6"
  p.author = "Robey Pointer"
  p.email = "robeypointer@gmail.com"
  p.project = "configgy"
  p.summary = "config file parser for ruby"
  p.rdoc_pattern = /README|TODO|LICENSE|CHANGELOG|BENCH|COMPAT|exceptions|behaviors|rails.rb/
  p.spec_pattern = "spec/*_spec.rb"
  p.ignore_pattern = [ "configgyrb.tmproj" ]
end

task :treetop do
  system("tt lib/treetop/configgy.treetop")
end
