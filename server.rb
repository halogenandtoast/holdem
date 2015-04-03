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

$games = [ Game.new(1) ]
server = TCPServer.new(2000)
semaphore = Mutex.new

loop do
  Thread.new(server.accept) do |client|
    $games.last.add_player(client)
  end
end
