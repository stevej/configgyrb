$LOAD_PATH << "lib"

require 'rubygems'
require 'treetop'
require 'treetop/configgy'

describe "ConfigParser" do
  before do
    @parser = ConfiggyParser.new
  end

  def parse(str)
    @parser.root = :root
    map = Configgy::ConfigMap.new(nil, "")
    @parser.parse(str).apply(map)
    map
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

  it "parses assignment" do
    parse("weight = 48").inspect.should == "{: weight=48}"
  end

  it "parses conditional assignment" do
    parse("weight = 48\n weight ?= 16").inspect.should == "{: weight=48}"
  end

  it "ignores comments" do
    parse("# doing stuff\n  weight = 48\n  # more comments\n").inspect.should == "{: weight=48}"
  end

  it "parses booleans" do
    parse("wine off\nwhiskey on\n").inspect.should == '{: whiskey=true wine=false}'
    parse("wine = false\nwhiskey = on\n").inspect.should == '{: whiskey=true wine=false}'
  end

  it "handles string lists" do
    b = parse('cats = ["Commie", "Buttons", "Sockington"]')
    b[:cats].should == [ 'Commie', 'Buttons', 'Sockington' ]
  end

  it "handles number lists" do
    b = parse('widths = [ 90, 100 ]')
    b[:widths].should == [ 90, 100 ]
  end

  it "handles lists without comma separators" do
    b = parse('cats = ["Commie" "Buttons" "Sockington"]')
    b[:cats].should == [ 'Commie', 'Buttons', 'Sockington' ]
  end

  it "handles lists with a trailing comma" do
    b = parse('cats = ["Commie", "Buttons", "Sockington",]')
    b[:cats].should == [ 'Commie', 'Buttons', 'Sockington' ]
  end

  #     "normal" in {
  #       val data =
  #         "<home>\n" +
  #         "    states = [\"California\", \"Tennessee\", \"Idaho\"]\n" +
  #         "    regions = [\"pacific\", \"southeast\", \"northwest\"]\n" +
  #         "</home>\n"
  #       val a = parse(data)
  #       a.toString mustEqual "{: home={home: regions=[pacific,southeast,northwest] states=[California,Tennessee,Idaho] } }"
  #       a.getList("home.states").toList.mkString(",") mustEqual "California,Tennessee,Idaho"
  #     }
end

#
# "ConfigParser" should {
#   "handle nested blocks" in {
#     parse("alpha=\"hello\"\n<beta>\n    gamma=23\n</beta>").toString mustEqual
#       "{: alpha=\"hello\" beta={beta: gamma=\"23\" } }"
#     parse("alpha=\"hello\"\n<beta>\n    gamma=23\n    toaster on\n</beta>").toString mustEqual
#       "{: alpha=\"hello\" beta={beta: gamma=\"23\" toaster=\"true\" } }"
#   }
#
#   "handle nested blocks in braces" in {
#     parse("alpha=\"hello\"\nbeta {\n    gamma=23\n}").toString mustEqual
#       "{: alpha=\"hello\" beta={beta: gamma=\"23\" } }"
#     parse("alpha=\"hello\"\nbeta {\n    gamma=23\n    toaster on\n}").toString mustEqual
#       "{: alpha=\"hello\" beta={beta: gamma=\"23\" toaster=\"true\" } }"
#   }
#
#   "import files" in {
#     val data1 =
#       "toplevel=\"skeletor\"\n" +
#       "<inner>\n" +
#       "    include \"test1\"\n" +
#       "    home = \"greyskull\"\n" +
#       "</inner>\n"
#     parse(data1).toString mustEqual "{: inner={inner: home=\"greyskull\" staff=\"weird skull\" } toplevel=\"skeletor\" }"
#
#     val data2 =
#       "toplevel=\"hat\"\n" +
#       "include \"test2\"\n" +
#       "include \"test4\"\n"
#     parse(data2).toString mustEqual "{: cow=\"moo\" inner={inner: cat=\"meow\" dog=\"bark\" } toplevel=\"hat\" }"
#   }
#   "catch unknown block modifiers" in {
#     parse("<upp name=\"fred\">\n</upp>\n") must throwA(new ParseException("Unknown block modifier"))
#   }
#
#   "handle an outer scope after a closed block" in {
#     val data =
#       "alpha = 17\n" +
#       "<inner>\n" +
#       "    name = \"foo\"\n" +
#       "    <further>\n" +
#       "        age = 500\n" +
#       "    </further>\n" +
#       "    zipcode = 99999\n" +
#       "</inner>\n" +
#       "beta = 19\n"
#     parse(data).toString mustEqual "{: alpha=\"17\" beta=\"19\" inner={inner: further={inner.further: age=\"500\" } name=\"foo\" zipcode=\"99999\" } }"
#   }
# }
