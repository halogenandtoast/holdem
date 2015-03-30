require "player"
require "round"

class Game
  def initialize
    @players = []
    run
  end

  def add_player(client)
    @players << Player.new(client)
  end

  def run
    Thread.new do
      begin
        loop do
          if @players.count == 2
            players.each do |player|
              player.game_start(money: 1000, number_of_players: @players.count, small_blind: 25, big_blind: 50, limit: true)
            end
            puts "PLAYING"
            round = Round.new(@players)
            round.play
            break if @players.reject(&:eliminated?).count == 1
          end
        end
        winner = @players.find { |player| !player.eliminated? }
        @players.each do |player|
          player.declare_winner(winner)
        end
        close
      rescue Exception => e
        puts e
      end
    end
  end

  def close
    players.each(&:close)
  end

  private

  attr_reader :deck, :players
end


