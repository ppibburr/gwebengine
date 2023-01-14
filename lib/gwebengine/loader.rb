GWEB_LIB_DIR = ENV["GWEB_LIB_DIR"] ||= "./build"

GObjectIntrospection::Repository.prepend_search_path(GWEB_LIB_DIR)
module GWebEngine
  class << self
    def const_set c,o
      if c.to_s == c.to_s.downcase
        c = c.to_s.upcase
        super c,o
      else
        super
      end
    end
  end

  class Loader < GObjectIntrospection::Loader
    def initialize(base_module, init_arguments)
      super(base_module)
      @init_arguments = init_arguments
    end

    def load
      self.version = "1.0"
      super("GWebEngine")
    rescue => e
      p e
    end
  end
end

GObjectIntrospection::Repository.prepend_search_path(GWEB_LIB_DIR)
module GWebEngineRuby
  class << self
    def const_set c,o
      if c.to_s == c.to_s.downcase
        c = c.to_s.upcase
        super c,o
      else
        super
      end
    end
  end

  class Loader < GObjectIntrospection::Loader
    def initialize(base_module, init_arguments)
      super(base_module)
      @init_arguments = init_arguments
    end

    def load
      self.version = "1.0"
      super("GWebEngineRuby")
    rescue => e
      p e
    end
  end
end


