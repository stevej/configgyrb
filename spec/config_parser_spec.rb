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

  it "interpolate strings" do
    parse('horse="ed" word="sch$(horse)ule"').inspect.should == '{: horse="ed" word="schedule"}'
    parse('lastname="Columbo" firstname="Bob" fullname="$(firstname) $(lastname)"').inspect.should ==
      '{: firstname="Bob" fullname="Bob Columbo" lastname="Columbo"}'
  end

  it "doesn't interpolate unassigned strings" do
    parse('horse="ed" word="sch\\$(horse)ule"').inspect.should == '{: horse="ed" word="sch$(horse)ule"}'
  end

  it "interpolates nested references" do
    parse('''horse="ed"
             alpha {
               horse="frank"
               drink="$(horse)ly"
               beta {
                 word="sch$(horse)ule"
                 greeting="$(alpha.drink) yours"
               }
             }
          ''').inspect.should == '{: alpha={alpha: beta={alpha.beta: greeting="frankly yours" word="schedule"} drink="frankly" horse="frank"} horse="ed"}'
  end

  it "interpolates environment vars" do
    ENV["GOOBER"] = "sparky"
    parse('user="$(GOOBER)"').inspect.should != '{: user="sparky"}'
  end

  it "inherits" do
    p = parse('''daemon {
                   ulimit_fd = 32768
                   uid = 16
                 }

                 upp (inherit="daemon") {
                   uid = 23
                 }
              ''')
    p.inspect.should == '{: daemon={daemon: uid=16 ulimit_fd=32768} upp={upp (inherit=daemon): uid=23}}'
    p["upp.ulimit_fd"].should == 32768
    p["upp.uid"].should == 23
  end

  it "uses parent scope for inherit lookups" do
    p = parse('''daemon {
                   inner {
                     common {
                       ulimit_fd = 32768
                       uid = 16
                     }
                     upp (inherit="common") {
                       uid = 23
                     }
                     slac (inherit="daemon.inner.common") {
                     }
                   }
                 }
              ''')
    p["daemon.inner.upp.ulimit_fd"].should == 32768
    p["daemon.inner.upp.uid"].should == 23
    p["daemon.inner.slac.uid"].should == 16
  end

  it "handles block names with dashes" do
    parse('''horse="ed"
             daemon {
               base-dat {
                 ulimit_fd = 32768
               }
             }
          ''').inspect.should == '{: daemon={daemon: base-dat={daemon.base-dat: ulimit_fd=32768}} horse="ed"}'
  end

  it "handles an assignment after a block" do
    parse('''daemon {
               base {
                 ulimit_fd = 32768
               }
               useless = 3
             }
          ''').inspect.should == '{: daemon={daemon: base={daemon.base: ulimit_fd=32768} useless=3}}'
  end

  it "handles two consecutive groups" do
    parse('''daemon {
               useless = 3
             }

             upp (inherit="daemon") {
               uid = 16
             }
          ''').inspect.should == '{: daemon={daemon: useless=3} upp={upp (inherit=daemon): uid=16}}'
  end

  it "handles a complex case" do
    p = parse('''daemon {
                   useless = 3
                   base {
                     ulimit_fd = 32768
                   }
                 }

                 upp (inherit="daemon.base") {
                   uid = 16
                   alpha (inherit="upp") {
                     name="alpha"
                   }
                   beta (inherit="daemon") {
                     name="beta"
                   }
                   some_int = 1
                 }
              ''')
    p.inspect.should == ('{: daemon={daemon: base={daemon.base: ulimit_fd=32768} useless=3} upp={upp (inherit=daemon.base): ' +
                         'alpha={upp.alpha (inherit=upp): name="alpha"} beta={upp.beta (inherit=daemon): name="beta"} some_int=1 uid=16}}'
    p["daemon.useless"].should == 3
    p["upp.uid"].should == 16
    p["upp.ulimit_fd"].should == 32768
    p["upp.name"].should == nil
    p["upp.alpha.name"].should == "alpha"
    p["upp.beta.name"].should == "beta"
    p["upp.alpha.ulimit_fd"].should == 32768
    p["upp.beta.ulimit_fd"].should == nil
    p["upp.alpha.useless"].should == nil
    p["upp.beta.useless"].should == 3
    p["upp.some_int"].should == 1
  end

end
