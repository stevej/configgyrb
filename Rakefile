
require 'rubygems'
gem 'treetop'
require 'echoe'

require 'spec/rake/spectask'

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

$LOAD_PATH << "lib"
Spec::Rake::SpecTask.new(:specs) do |t|
  # why is color misspelled?
  t.spec_opts = [ '--colour', '--format progress', '--loadby mtime', '--reverse' ]
  t.spec_files = FileList['spec/*_spec.rb']
end

task :specx do
  system("spec ./test/unit/*_spec.rb")
end
