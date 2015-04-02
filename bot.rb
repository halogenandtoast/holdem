require "socket"
require "json"

2.times.map do |i|
  Thread.new do
    client = TCPSocket.new 'localhost', 2000

    while line = client.gets
      json = JSON.parse(line)
      puts json
      if json["event"] == "choice"
        choice = %w(RAISE CALL FOLD).sample
        puts "Rando #{i} will #{choice}"
        client.puts choice
      elsif json["event"] == "game_over"
        puts "WINNERS DECLARED"
        break
      elsif json["event"] == "get_name"
        client.puts "Rando #{i}"
      end
    end
  end
end.map(&:join)
