$LOAD_PATH.unshift "."

require "socket"
require "json"
require "game"

def catch_errors(&block)
  begin
    block.call
  rescue Exception => e
    binding.pry
    puts e.inspect
  end
end


trap(:INT) { exit }
players = {}

games = [ Game.new ]
server = TCPServer.new(2000)

loop do
  Thread.new(server.accept) do |client|
    catch_errors do
      games.last.add_player(client)
      if games.last.started
        games << Game.new
      end
    end
  end
end.join
