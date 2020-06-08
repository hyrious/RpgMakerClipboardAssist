
require "zlib"
require "fileutils"
include FileUtils

screen_size = [400, 600]

cd __dir__ do
  open "Scripts.rvdata2", "wb" do |f|
    f.write Marshal.dump [
                   [rand(32767), "Main", Zlib.deflate('load "Data/main.rb"')],
                 ]
  end
  cd ".." do
    config = File.read("Game.ini").encode("utf-8", "gbk")
      .sub(/ScreenWidth=\d+/, "ScreenWidth=#{screen_size[0]}")
      .sub(/ScreenHeight=\d+/, "ScreenHeight=#{screen_size[1]}")
    File.write "Game.ini", config.encode("gbk")
  end
end
