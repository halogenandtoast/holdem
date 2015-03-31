require "player"
require "round"

class Game
  def initialize
    @players = []
    run
  end

  def add_player(client)
    players << Player.new(client)
  end

  def run
    Thread.new do
      catch_errors do
        run_game
        declare_winner
        close
      end
    end
  end

  def play_

  def close
    players.each(&:close)
  end

  private

  attr_reader :deck, :players

  def has_winner?
    players.reject(&:eliminated?).count == 1
  end

  def winner
    players.find { |player| !player.eliminated? }
  end

  def declare_winner
    players.each { |player| player.declare_winner(winner) }
  end

  def run_game
    loop do
      if players.count == 2
        play_round
        break if has_winner?
      end
    end
  end

  def play_round
    setup_players
    round = Round.new(players)
    round.play
  end

  def setup_players
    players.each do |player|
      player.game_start(money: 1000, number_of_players: players.count, small_blind: 25, big_blind: 50, limit: true)
    end
  end
end
