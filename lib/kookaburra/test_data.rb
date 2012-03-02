class Kookaburra
  class TestData
    def initialize
      @data = {}
    end

    def method_missing(name)
      @data[name] ||= {}
    end
  end
end
