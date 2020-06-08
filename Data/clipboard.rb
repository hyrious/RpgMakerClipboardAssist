
require_relative 'winapi'

module Clipboard
  def self.init
    @r = WinApi.kernel32.GetCurrentProcess()
    raise "cannot open process" if @r == 0
  end

  init

  def self.open
    WinApi.user32.OpenClipboard(0); @o = true
    return yield.tap { close } if block_given?
  end

  def self.close
    WinApi.user32.CloseClipboard(); @o = false
  end

  def self.clear
    return open { clear } unless @o
    WinApi.user32.EmptyClipboard() != 0
  end

  def self.format(f=1)
    return f if f.kind_of? Integer
    (@f ||= {})[f.to_sym] ||= WinApi.user32.RegisterClipboardFormat(f.to_s)
  end

  def self.[](f=1)
    f = format(f)
    return if WinApi.user32.IsClipboardFormatAvailable(f) == 0
    return open { self[f] } unless @o
    h = WinApi.user32.GetClipboardData(f)
    return if h.zero?
    s = WinApi.kernel32.GlobalSize(h)
    a = WinApi.kernel32.GlobalLock(h)
    return if a.zero?
    b = "\0" * s
    WinApi.kernel32.ReadProcessMemory(@r, a, b, s, 0)
    WinApi.kernel32.GlobalUnlock(h)
    return b
  end

  singleton_class.class_eval { alias data [] }

  def self.text
    self.data 1
  end

  def self.[]=(f, b)
    f = format(f)
    return open { self[f] = b } unless @o
    h = WinApi.kernel32.GlobalAlloc(0x42, b.bytesize)
    a = WinApi.kernel32.GlobalLock(h)
    WinApi.kernel32.WriteProcessMemory(@r, a, b, b.bytesize, 0)
    WinApi.user32.SetClipboardData(f, h)
    WinApi.kernel32.GlobalFree(h)
    return b
  end

  def self.text=(b)
    return open { self.text = b } unless @o
    self[1] = self[7] = b
    self[13] = b.unpack('U*').pack('S*')
  end
end
