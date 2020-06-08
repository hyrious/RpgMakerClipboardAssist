
require_relative 'winapi'

hstdout = WinApi.kernel32.GetStdHandle(-11)
WinApi.kernel32.GetConsoleMode(hstdout, buf = "\0" * 4)
WinApi.kernel32.SetConsoleMode(hstdout, buf.unpack("L")[0] | 4)

if $RGD and RGD.respond_to?(:console_input)
  def gets
    ret = ret
    loop do
      ret = RGD.console_input
      break unless ret.empty?
      Graphics.update
    end
    ret = "" if ret == "\r"
    return ret
  end
else
  # https://rpg.blue/thread-400462-1-1.html
  # by Fux2 20170510 21:47:15

  module Fux2
    module Win32Tools
      ReadProcessMemory = Win32API.new("kernel32", "ReadProcessMemory", "llpll", "l")
      WriteProcessMemory = Win32API.new("kernel32", "WriteProcessMemory", "llpll", "l")
      VirtualProtect = Win32API.new("kernel32", "VirtualProtect", "lllp", "l")
      GetModuleHandle = Win32API.new("kernel32", "GetModuleHandle", "p", "l")
      GetProcAddress = Win32API.new("kernel32", "GetProcAddress", "lp", "l")
      GetCurrentProcess = Win32API.new("kernel32", "GetCurrentProcess", "v", "l")

      module_function

      def readmem(addr, buf, len)
        ReadProcessMemory.call(@@hProc, addr, buf, len, 0)
      end

      def writemem(addr, buf, len)
        WriteProcessMemory.call(@@hProc, addr, buf, len, 0)
      end

      def unprotect(addr, len)
        VirtualProtect.call(addr, len, 0x40, "\0" * 4)
      end

      def getmodule(name)
        GetModuleHandle.call(name)
      end

      def getaddr(dll, name)
        GetProcAddress.call(dll, name)
      end

      def init
        @@hProc = GetCurrentProcess.call
        raise "cannot open process" if @@hProc == 0
      end

      init
    end

    class ReadFileHooker
      include Win32Tools

      HookCode = ([0xC7, 0x44, 0x24, 0x0C, 0x12, 0x05, 0x00, 0x00] + [0] * 6).pack("C*")

      def SetHookOn
        cad = @code_address
        cal = @code_length

        hook_addr = cad - @proc - 5
        Win32Tools.writemem(cad + cal - 6, @origin_code_readfile, 6)
        Win32Tools.writemem(@proc, [0xE9, hook_addr, 0x90].pack("ClC"), 6)
      end

      def SetHookOff
        return unless @origin_code_readfile
        Win32Tools.writemem(@proc, @origin_code_readfile, 6)
      end

      def initialize
        dll = Win32Tools.getmodule("kernel32")
        @proc = Win32Tools.getaddr(dll, "ReadFile")
        @code_address = [HookCode].pack("p").unpack("L")[0]
        @code_length = HookCode.bytesize
        @origin_code_readfile = "\0" * 6
        Win32Tools.readmem(@proc, @origin_code_readfile, 6)
        unprotect(@code_address, @code_length)
      end
    end
  end

  class << STDIN
    def hack
      @tool = Fux2::ReadFileHooker.new
      alias _gets gets

      def gets
        @tool.SetHookOn
        ret = _gets
        @tool.SetHookOff
        return ret
      end
    end
  end

  STDIN.hack

  def gets
    ansi = STDIN.gets
    ansi_len = ansi.bytesize
    # 1. ANSI -> WideChar
    wide_len = WinApi.kernel32.MultiByteToWideChar 0, 0, ansi, ansi_len, 0, 0
    wide_buffer = "\0" * wide_len * 2
    WinApi.kernel32.MultiByteToWideChar 0, 0, ansi, ansi_len, wide_buffer, wide_len
    # 2. WideChar -> UTF-8
    utf8_len = WinApi.kernel32.WideCharToMultiByte 65001, 0, wide_buffer, wide_len, 0, 0, 0, 0
    utf8_buffer = "\0" * utf8_len
    WinApi.kernel32.WideCharToMultiByte 65001, 0, wide_buffer, wide_len, utf8_buffer, utf8_len, 0, 0
    # 3.
    return utf8_buffer.force_encoding("utf-8").chomp
  end
end
