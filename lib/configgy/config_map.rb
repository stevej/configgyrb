module Configgy
  class ConfigMap
    attr_reader :name, :cells
    attr_accessor :monitored

    def initialize(root, name)
      @root = root
      @name = name
      @monitored = false
      @inherit_from = nil
      @cells = {}
    end

    def create_nested(key)
      config_map = ConfigMap.new(@root, name == "" ? key : name + "." + key)
      config_map.monitored = @monitored
      @cells[key] = config_map
    end

    # find (ConfigMap, key) after following any dot-separated names
    def recurse(key, &block)
      left, right = key.split(".", 2)
      if right
        create_nested(left) unless @cells.has_key?(left)
        raise ConfigException("illegal key #{key}") unless @cells[left].respond_to?(:recurse)
        @cells[left].recurse(right, &block)
      else
        yield [ self, key ]
      end
    end

    def lookup_cell(key)
      left, right = key.split(".", 2)
      if @cells.has_key?(left)
        if right
          if @cells[left].respond_to?(:lookup_cell)
            @cells[left].lookup_cell(right)
          else
            nil
          end
        else
          @cells[left]
        end
      elsif @inherit_from
        @inherit_from.lookup_cell(key)
      else
        nil
      end
    end

    def []=(key, value)
      key = key.to_s
      if @monitored
        @root.deep_set(@name, key, value)
      else
        recurse(key) do |config_map, key|
          config_map.cells[key] = value
        end
      end
    end

    def [](key)
      lookup_cell(key.to_s)
    end

    def ==(other)
      other.instance_of?(self.class) and @cells == other.cells
    end

    def inspect
      "{#{@name}" + (@inherit_from ? " (inherit=#{@inherit_from.name})" : "") + ": " + @cells.keys.sort.map { |k| "#{k}=#{@cells[k].inspect}" }.join(" ") + "}"
    end
  end
end
