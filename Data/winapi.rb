
module WinApi
  class Dll
    def initialize(dll)
      @dll = dll.to_s
    end

    def method_missing(func, *args)
      imports = args.map { |e| Integer === e ? "L" : "p" }
      Win32API.new(@dll, func.to_s, imports, "L").call(*args)
    end
  end

  @dll = {}

  def self.method_missing(dll)
    @dll[dll] ||= Dll.new(dll)
  end
end
