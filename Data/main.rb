
load "Data/console.rb" if $TEST

load 'Data/clipboard.rb'

if $RGD
  Graphics.vsync = false
  Graphics.background_exec = true
end
Graphics.frame_rate = 240

loop do
  Input.update
  Graphics.update
end
