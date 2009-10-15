$LOAD_PATH << "lib"

require 'rubygems'
require 'configgy/config_map'

describe "ConfigMap" do
  before do
    @map = Configgy::ConfigMap.new(nil, "root")
  end

  it "sets values" do
    @map.inspect.should == '{root: }'
    @map[:name] = "Communist"
    @map.inspect.should == '{root: name="Communist"}'
    @map[:age] = 8
    @map.inspect.should == '{root: age=8 name="Communist"}'
    @map[:age] = 19
    @map.inspect.should == '{root: age=19 name="Communist"}'
    @map[:sleepy] = true
    @map.inspect.should == '{root: age=19 name="Communist" sleepy=true}'
  end

  it "gets values" do
    @map[:name] = "Communist"
    @map[:age] = 8
    @map[:sleepy] = true
    @map[:money] = 1900500400300
    @map[:name].should == "Communist"
    @map[:age].should == 8
    @map[:unknown].should == nil
    @map[:money].should == 1900500400300
    @map[:sleepy].should == true
  end

  it "sets compound values" do
    @map[:name] = "Communist"
    @map[:age] = 8
    @map[:disposition] = "fighter"
    @map["diet.food"] = "Meow Mix"
    @map["diet.liquid"] = "water"
    @map[:data] = "\r\r"
    @map.inspect.should == '{root: age=8 data="\\r\\r" diet={root.diet: food="Meow Mix" liquid="water"} disposition="fighter" name="Communist"}'
  end

  it "knows what it contains" do
    @map[:name] = "Communist"
    @map[:age] = 8
    @map["diet.food"] = "Meow Mix"
    @map["diet.liquid"] = "water"
    @map["age"].should_not == nil
    @map["unknown"].should == nil
    @map["diet.food"].should_not == nil
    @map["diet.gas"].should == nil
  end

  it "auto-vivifies" do
    @map["a.b.c"] = 8
    @map.inspect.should == "{root: a={root.a: b={root.a.b: c=8}}}"
    @map["a.d.x"].should == nil
    @map.inspect.should == "{root: a={root.a: b={root.a.b: c=8}}}"
  end

  it "compares with ==" do
    @map[:name] = "Communist"
    @map[:age] = 8
    @map["diet.food.dry"] = "Meow Mix"
    map2 = Configgy::ConfigMap.new(nil, "root")
    map2[:name] = "Communist"
    map2[:age] = 8
    map2["diet.food.dry"] = "Meow Mix"
    @map.should == map2
  end

  it "removes values" do
    @map[:name] = "Communist"
    @map[:age] = 8
    @map["diet.food"] = "Meow Mix"
    @map["diet.liquid"] = "water"
    @map.inspect.should == '{root: age=8 diet={root.diet: food="Meow Mix" liquid="water"} name="Communist"}'
    @map.delete("diet.food").should == "Meow Mix"
    @map.delete("diet.food").should == nil
    @map.inspect.should == '{root: age=8 diet={root.diet: liquid="water"} name="Communist"}'
    @map.delete("age").should == 8
    @map.delete("age").should == nil
    @map.inspect.should == '{root: diet={root.diet: liquid="water"} name="Communist"}'
  end

  it "converts to a map" do
    @map[:name] = "Communist"
    @map[:age] = 8
    @map["diet.food"] = "Meow Mix"
    @map["diet.liquid"] = "water"
    @map.to_map.should == { "name" => "Communist", "age" => 8, "diet" => { "food" => "Meow Mix", "liquid" => "water" } }
  end

  it "dupes" do
    @map[:name] = "Communist"
    @map[:age] = 8
    @map["diet.food"] = "Meow Mix"
    @map["diet.liquid"] = "water"
    t = @map.dup
    @map.inspect.should == '{root: age=8 diet={root.diet: food="Meow Mix" liquid="water"} name="Communist"}'
    t.inspect.should == '{root: age=8 diet={root.diet: food="Meow Mix" liquid="water"} name="Communist"}'

    @map["diet.food"] = "fish"
    @map[:age] = 9
    @map.inspect.should == '{root: age=9 diet={root.diet: food="fish" liquid="water"} name="Communist"}'
    t.inspect.should == '{root: age=8 diet={root.diet: food="Meow Mix" liquid="water"} name="Communist"}'
  end

  it "dupes with inheritance" do
    @map[:name] = "Communist"
    @map[:age] = 8
    ancestor = Configgy::ConfigMap.new(nil, "ancestor")
    ancestor[:age] = 12
    ancestor[:disposition] = "hungry"
    @map.inherit_from = ancestor

    t = @map.dup
    @map.inspect.should == '{root (inherit=ancestor): age=8 name="Communist"}'
    t.inspect.should == '{root: age=8 disposition="hungry" name="Communist"}'
  end

  it "creates a config string" do
    @map[:name] = "Sparky"
    @map[:age] = 10
    @map[:diet] = "poor"
    @map["muffy.name"] = "Muffy"
    @map["muffy.age"] = 11
    @map["fido.name"] = "Fido"
    @map["fido.age"] = 5
    @map["fido.roger.name"] = "Roger"
    @map["fido.roger"].inherit_from = @map[:muffy]
    @map.to_config_string.should == <<-END
age = 10
diet = "poor"
fido {
  age = 5
  name = "Fido"
  roger (inherit="root.muffy") {
    name = "Roger"
  }
}
muffy {
  age = 11
  name = "Muffy"
}
name = "Sparky"
END
  end
end
