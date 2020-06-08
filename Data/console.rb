
load "Data/gets.rb"
require_relative 'winapi'

CONSOLE_SKIP = Object.new
CONSOLE_HWND = WinApi.kernel32.GetConsoleWindow
CONSOLE_BINDING = TOPLEVEL_BINDING.dup

def cd(obj=nil)
  $console_binding = obj && obj.instance_eval { binding }
  puts console_binding_inspect
  return CONSOLE_SKIP
end

def clear
  print "\e[H\e[2J"
  return CONSOLE_SKIP
end

def console_binding_inspect
  this = $console_binding || CONSOLE_BINDING
  "\e[36m-> \e[32m#< #{eval('self', this) || 'main'} >\e[m"
end

class << Input
  def console_eval str
    if $console_binding.nil?
      eval str, CONSOLE_BINDING
    else
      eval str, $console_binding
    end
  end

  alias _update_console update
  def update
    _update_console
    if trigger? :F8
      print console_binding_inspect
      if $RGD and RGD.respond_to? :console_input
        puts
      else
        puts " (note: not support ctrl-c, use 'exit')"
      end
      hwnd = WinApi.user32.GetActiveWindow
      WinApi.user32.SetForegroundWindow CONSOLE_HWND
      loop do
        print ">> "
        begin
          ret = console_eval gets
          unless ret == CONSOLE_SKIP
            print "=> "
            p ret
          end
        rescue Interrupt
          puts "^C"
          break
        rescue SystemExit
          break
        rescue Exception => e
          puts "#{e.class}: #{e}", e.backtrace
        end
      end
      if Graphics.respond_to? :window_hwnd
        WinApi.user32.SetForegroundWindow Graphics.window_hwnd
      else
        WinApi.user32.SetForegroundWindow hwnd
      end
    end
  end
end
