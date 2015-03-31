$LOAD_PATH.unshift "."

require "socket"
require "json"
require "game"

trap(:INT) { exit }
players = {}

games = [ Game.new ]
server = TCPServer.new(2000)

def catch_errors(&block)
  begin
    block.call
  rescue Exception => e
    puts e.inspect
  end
end

loop do
  Thread.new(server.accept) do |client|
    catch_errors do
      client.puts({ event: "waiting" })
      game.last.add_player(client)
    end
  end
end.join
