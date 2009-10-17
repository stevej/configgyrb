module Configgy
  class ConfigParser < Treetop_ConfiggyParser
    def import_file(filename)
      File.open(filename, "r").read
    end

    def read(s, map=nil)
      if !map
        map = Configgy::ConfigMap.new(nil, "")
        map.root = map
      end
      parse(s).apply(map, self)
      map
    end

    def load_file(filename, map=nil)
      read(import_file(filename), map)
    end
  end
end
