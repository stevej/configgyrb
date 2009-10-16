require "rubygems"
require "treetop"
require "treetop/configgy"
require "configgy/config_map"
require "configgy/config_parser"

class ConfigException < RuntimeError; end
