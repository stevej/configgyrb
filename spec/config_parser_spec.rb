$LOAD_PATH << "lib"

require 'rubygems'
require 'treetop'
require 'treetop/configgy'

describe "ConfigParser" do
  before do
    @parser = ConfiggyParser.new
  end

  def parse(str)
    @parser.parse(str).to_value
  end

  def unquoted(str)
    @parser.root = :string
    @parser.parse(str).to_value
  end

  it "unquotes strings" do
    unquoted('"nothing"').should == "nothing"
    unquoted('"name\\tvalue\\t\\x44b\\xfcllet?"').should == "name\tvalue\tDb\xfcllet?"
    unquoted('"name\\tvalue\\t\\u20acb\\u00fcllet?\\u20ac"').should == "name\tvalue\t\342\202\254b\303\274llet?\342\202\254"
    unquoted('"she said \\"hello\\""').should == "she said \"hello\""
    unquoted('"\\\\backslash"').should == "\\backslash"
    unquoted('"real\\$dollar"').should == "real\\$dollar"
    unquoted('"silly\\/quote"').should == "silly/quote"
  end
end
