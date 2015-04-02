require "timeout"
require "best_hand"

class Player
  attr_reader :money
  def initialize(client)
    @client = client
  end

  def name
    "foo"
  end

  def game_start(options)
    @base_money = options[:money]
    event("game_start",
          money: @base_money,
          number_of_players: options[:number_of_players],
          small_blind: options[:small_blind],
          big_blind: options[:big_blind])
  end

  def best_hand(table_cards)
    cards = @hand + table_cards
    BestHand.new(cards).determine
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
    event("hold", cards: cards)
  end

  def get_choice(table)
    puts "PLAYER CHOICE"
    event("choice", table: table)

    choice = nil

    begin
      Timeout::timeout(6) { choice = @client.gets.strip }
    rescue Timeout::Error
      event("timeout")
      choice = "FOLD"
    end

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

  def showdown(player, showdown_players, players)
    event("showdown", winner: player, players: players.map { |player| player.as_json(showdown_players) })
  end

  def to_json(showdown_players)
    if showdown_players.include? self
      { name: name, in_showdown: true, hand: @hand, money: @money }
    else
      { name: name, in_showdown: false, money: @money }
    end
  end

  def declare_winner(player)
    event("game_over", winner: player.name, won: player == self)
  end

  def start_round_in_position(position)
    event("round_start", position: position)
  end

  def close
    @client.close
  end

  private

  def event(name, options = {})
    @client.puts(options.merge(event: name).to_json)
  end
end

