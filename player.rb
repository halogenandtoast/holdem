require "timeout"
require "best_hand"

class Player
  attr_accessor :money, :sidepots
  attr_reader :bid, :all_in
  attr_writer :eliminated

  def initialize(client)
    @client = client
    event("get_name")
    @eliminated = false
    @name = client.gets.strip
    puts "#{@name} has joined"
  end

  def name
    @name
  end

  def game_start(options)
    @money = options[:money]
    event("game_start",
          money: @money,
          number_of_players: options[:number_of_players],
          small_blind: options[:small_blind],
          big_blind: options[:big_blind])
  end

  def best_hand(table_cards)
    cards = @hand + table_cards
    BestHand.new(cards).determine
  end

  def reset
    @hand = []
    @folded = false
    @all_in = false
    @sidepots = 0
    @bid = 0
  end

  def out?
    @folded || @eliminated
  end

  def eliminated?
    @eliminated
  end

  def deal(cards)
    @hand += cards
    event("hole", cards: cards)
  end

  def round_over(winner)
    event("round_over", winner: winner.as_json([]))
  end

  def can_bid?
    !out? && !@all_in
  end

  def get_choice(table)
    event("choice", table: table)

    choice = nil

    begin
      Timeout::timeout(6) { choice = @client.gets.strip }
    rescue Timeout::Error
      event("timeout")
      @folded = true
      choice = "FOLD"
    end

    case choice.upcase
    when "RAISE"
      diff = (table[:bids].last - @bid) + table[:raise_amount]
      amount = [diff, @money].min
      @money -= amount
      @bid += amount
      table[:pot] += amount
      if @money == 0
        puts "#{name} is raising all in: #{@bid}"
        @all_in = true
        table[:bids].unshift @bid
      else
        puts "#{name} raised: #{@bid}"
        table[:bids] << @bid
      end
    when "FOLD"
      puts "#{name} folded: #{@bid}"
      @folded = true
    when "CALL"
      diff = table[:bids].last - @bid
      amount = [diff, @money].min
      @money -= amount
      @bid += amount
      table[:pot] += amount
      if @money == 0
        puts "#{name} is all in: #{@bid}"
        @all_in = true
        table[:bids].unshift @bid
      else
        table[:bids] << @bid
      end
      puts "#{name} called: #{@bid}"
    end

    choice
  end

  def big_blind(table)
    amount = [table[:big_blind], @money].min
    @money -= amount
    @bid += amount
    table[:bids] << @bid
    table[:pot] += @bid
    if @money == 0
      @all_in = true
    end
    event("big_blind", amount: amount)
  end

  def small_blind(table)
    amount = [table[:small_blind], @money].min
    @money -= amount
    @bid += amount
    table[:pot] += @bid
    table[:bids] << @bid
    if @money == 0
      @all_in = true
    end
    event("small_blind", amount: amount)
  end

  def showdown(player, showdown_players, players, best_hands)
    event("showdown", winner: player, players: players.map { |player| player.as_json(showdown_players, best_hands) })
  end

  def as_json(showdown_players, best_hands = {})
    if showdown_players.include? self
      { name: name, in_showdown: true, hand: @hand, money: @money, best_hand: best_hands[self] }
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

  def sidepot(amount)
    event("sidepot", amount: amount)
  end

  private

  def event(name, options = {})
    @client.puts(options.merge(event: name).to_json)
  end
end

