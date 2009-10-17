$LOAD_PATH << "lib"

require 'rubygems'
require 'configgy'

describe "ConfigParser" do
  before do
    @parser = Configgy::ConfigParser.new
  end

  def parse(str)
    @parser.root = :root
    @parser.read(str)
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

  it "handles nested blocks" do
    parse('''alpha="hello"
             beta {
               gamma=23
             }
          ''').inspect.should == '{: alpha="hello" beta={beta: gamma=23}}'
    parse('''alpha="hello"
             beta {
               gamma=23
               toaster on
             }
          ''').inspect.should == '{: alpha="hello" beta={beta: gamma=23 toaster=true}}'
    parse('''home {
               states = ["California", "Tennessee", "Idaho"]
               regions = ["pacific", "southeast", "northwest"]
             }
          ''').inspect.should == '{: home={home: regions=["pacific", "southeast", "northwest"] states=["California", "Tennessee", "Idaho"]}}'
  end

  it "handles items after closing a block" do
    parse('''alpha = 17
             inner {
               name = "foo"
               further {
                 age = 500
               }
               zipcode = 99999
             }
             beta = 19
          ''').inspect.should == '{: alpha=17 beta=19 inner={inner: further={inner.further: age=500} name="foo" zipcode=99999}}'
  end

  it "imports files" do
    def @parser.load_file(filename, map=nil)
      if filename == "test1"
        read("staff=\"weird skull\"\n", map)
      end
    end

    parse('''toplevel = "skeletor"
             inner {
               include "test1"
               home = "greyskull"
             }
          ''').inspect.should == '{: inner={inner: home="greyskull" staff="weird skull"} toplevel="skeletor"}'
  end

  it "imports multiple, nested files" do
    def @parser.load_file(filename, map=nil)
      if filename == "test2"
        data = '''
          inner {
            cat="meow"
            include "test3"
            dog ?= "blah"
          }
        '''
      end
      if filename == "test3"
        data = '''
          dog="bark"
          cat ?= "blah"
        '''
      end
      if filename == "test4"
        data = '''
          cow = "moo"
        '''
      end
      read(data, map)
    end

    parse('''toplevel = "hat"
             include "test2"
             include "test4"
          ''').inspect.should == '{: cow="moo" inner={inner: cat="meow" dog="bark"} toplevel="hat"}'
  end
end
