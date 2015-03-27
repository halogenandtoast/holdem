=begin
<card> format is a string "AH", "TC", "2S", etc.
<type> is "raise", "fold", "call"
<player_event> is { type: <type> } a raise type will include amount: x if limit is false in "game_start" event

{ event: "waiting" }
{ event: "game_start", money: 1000, number_of_players: 4, small_blind: 1, big_blind: 2, limit: bool } # limit is randomly assigned
{ event: "big_blind" }
{ event: "little_blind" }
{ event: "round_start", position: 1} # position 1 is player after the dealer and dealer will have the highest position
{ event: "choice", table: {
  betting_round: 1 # up to 4
  pot: 0,
  flop: [(<card>, <card>, <card>)?], #either empty of three cards
  turn: [<card>?], # either an array of a single card or empty
  river: [<card>?], # either an array of a single card of empty
  events: [(<player_event>, ...)?], # zero or more player events
  bids: [{ name: name, position: 1, amount: amount}]
} }

{ event: "time_out" } # automatically fold
{ event: "invalid_command" } # automatically fold, closes connection, happens when you issue a command out of turn or an invalid choice

{ event: "hole", cards: [<card>, <card>] } # will contain two cards

{ event: "showdown", winner: player, players: [{ name: name, in_showdown: true, hand: hand }, ...]}
{ event: "game_over", winner: player }
=end

require "socket"
require "json"

trap(:INT) { exit }
players = {}

SUITS = %w(S H C D)
VALUES = 1..13

class Card < Struct.new(:suit, :value); end

class Player
  attr_reader :money
  def initialize(client)
    @client = client
  end

  def name
    "foo"
  end

  def reset
    @money = 1000
    @hand = []
    @eliminated = false
    @all_in = false
  end

  def eliminated?
    @eliminated
  end

  def deal(cards)
    @hand << cards
    @client.puts({ event: { type: "dealt", cards: cards} }.to_json)
  end

  def get_choice(table)
    puts "PLAYER CHOICE"
    @client.puts(table.to_json)
    choice = @client.gets.strip
    case choice.upcase
    when "RAISE"
      puts "RAISING"
      amount = [table[:raise_amount], @money].min
      @money -= amount
      table[:pot] += amount
      if @money == 0
        @all_in = true
      end
      puts "DONE RAISING"
    when "FOLD"
      puts "FOLDING"
      @eliminated = true
    when "CALL"
      puts "CALLING"
    end
    choice
  end

  def close
    @client.close
  end
end

class Round
  def initialize(players)
    @deck = Deck.build.shuffle
    @players = players
    @players.map(&:reset)

    @hands = @players.each_with_object({}) do |player, hash|
      hash[player] = []
    end

    @bids = @players.each_with_object({}) do |player, hash|
      hash[player] = 0
    end

    @table = {
      raise_amount: 100,
      pot: 0,
      flop: [],
      turn: [],
      river: [],
      events: [],
      bids: @bids
    }
  end

  def play
    deal_hole
    get_choices
  end

  def get_choices
    puts "GETTING CHOICES"
    @players.reject(&:eliminated?).each do |player|
      puts "GETTING CHOICE"
      choice = player.get_choice(@table)
      case choice
      when "FOLD"
        @table[:events] << "#{player.name} FOLDED"
      when "CALL"
        @table[:events] << "#{player.name} CALLED"
      when "RAISE"
        @table[:events] << "#{player.name} RAISED"
      end
    end
  end

  def deal_hole
    puts "DEALING HOLE"
    @players.each do |player|
      hole = @deck.pop(2)
      @hands[player] << hole
      player.deal(hole)
    end
    puts "DEALT HOLE"
  end

end

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
      loop do
        if @players.count == 2
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
    end
  end

  def close
    players.each(&:close)
  end

  private

  attr_reader :deck, :players
end

class Deck
  def self.build
    SUITS.flat_map do |suit|
      VALUES.map do |value|
        Card.new(suit, value)
      end
    end
  end
end

games = [ Game.new ]
server = TCPServer.new(2000)

Thread.new do
  loop do
    Thread.new(server.accept) do |client|
      begin
        games.last.add_player(client)
      rescue Exception => e
        puts e.inspect
      end
    end
  end
end.join
