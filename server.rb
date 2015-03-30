$LOAD_PATH.unshift "."

require "socket"
require "json"
require "game"

trap(:INT) { exit }
players = {}

games = [ Game.new ]
server = TCPServer.new(2000)

Thread.new do
  loop do
    Thread.new(server.accept) do |client|
      client.puts({ event: "waiting" })
      begin
        games.last.add_player(client)
      rescue Exception => e
        puts e.inspect
      end
    end
  end
end.join
