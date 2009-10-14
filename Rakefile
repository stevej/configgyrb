
require 'rubygems'
gem 'treetop'
require 'echoe'

task :echoe do
  Echoe.new("configgy") do |p|
    p.author = "Robey Pointer"
    p.project = "configgy"
    p.summary = "config file parser for ruby"
    p.rdoc_pattern = /README|TODO|LICENSE|CHANGELOG|BENCH|COMPAT|exceptions|behaviors|rails.rb/
  end
end

task :treetop do
  system("tt lib/treetop/configgy.treetop")
end

task :test do
  system("ruby -Ilib ./test/unit/*.rb")
end
