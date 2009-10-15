require 'rubygems'
require 'test/unit'
require "treetop"
require 'treetop/configgy.rb'


class ConfiggyParserTest < Test::Unit::TestCase
  def setup
    @parser = ConfiggyParser.new
  end

  def parse(str)
    @parser.parse(str).to_value
  end

  def unquoted(str)
    @parser.root = :string
    @parser.parse(str).to_value
  end

  def test_unquote_c
    assert_equal "nothing", unquoted('"nothing"')
    assert_equal "name\tvalue\tDb\xfcllet?", unquoted('"name\\tvalue\\t\\x44b\\xfcllet?"')
    assert_equal "name\tvalue\t\342\202\254b\303\274llet?\342\202\254", unquoted('"name\\tvalue\\t\\u20acb\\u00fcllet?\\u20ac"')
    assert_equal "she said \"hello\"", unquoted('"she said \\"hello\\""')
    assert_equal "\\backslash", unquoted('"\\\\backslash"')
    assert_equal "real\\$dollar", unquoted('"real\\$dollar"')
    assert_equal "silly/quote", unquoted('"silly\\/quote"')
  end

end

# class ConfiggyTest < Test::Unit::TestCase
# 
#   def setup
#   end
# 
# end
