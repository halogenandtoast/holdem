require "socket"
require "json"

4.times.map do |i|
  Thread.new do
    client = TCPSocket.new 'localhost', 2000

    while line = client.gets
      json = JSON.parse(line)
      puts json
      case json["event"]
      when "choice"
        choice = %w(RAISE CALL FOLD).sample
        puts "Rando #{i} will #{choice}"
        client.puts choice
      when "game_over"
        puts "WINNERS DECLARED"
        break
      when "get_name"
        client.puts "Rando #{i}"
      end
    end
  end
end.map(&:join)
