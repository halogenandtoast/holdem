require "player"
require "round"

class Game
  attr_reader :started
  def initialize(id)
    puts "CREATING GAME #{id}"
    @id = id
    @started = false
    @players = []
    run
  end

  def add_player(client)
    players << Player.new(client)
    puts "Added #{players.last.name} to #{@id}"
  end

  def run
    Thread.new do
      run_game
      declare_winner
      close
    end
  end

  def close
    players.each(&:close)
  end

  private

  attr_reader :deck, :players

  def has_winner?
    players.reject { |player| player.money == 0 }.count == 1
  end

  def winner
    players.find { |player| !player.eliminated? }
  end

  def declare_winner
    players.each { |player| player.declare_winner(winner) }
  end

  def run_game
    loop do
      if players.count == ENV.fetch("PLAYER_COUNT", 4)
        $games << Game.new(@id + 1)
        if !@started
          puts "STARTED GAME #{@id}"
          @started = true
          setup_players
        end
        play_round
        if !has_winner?
          players.rotate!
          while players.first.eliminated?
            players.rotate!
          end
        else
          break
        end
      else
        sleep 5
      end
    end
  end

  def play_round
    round = Round.new(players, small_blind: 25, big_blind: 50, limit: true, number_of_players: players.count)
    round.play
  end

  def setup_players
    players.each do |player|
      player.game_start(money: 1000, number_of_players: players.count, small_blind: 25, big_blind: 50, limit: true)
    end
  end
end
