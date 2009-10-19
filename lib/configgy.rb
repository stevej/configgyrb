require "rubygems"
require "treetop"
require "treetop/configgy"
require "configgy/config_map"
require "configgy/config_parser"

class ConfigException < RuntimeError; end

module Configgy
  def self.load_file(filename)
    Configgy::ConfigParser.new.load_file(filename)
  end
end
