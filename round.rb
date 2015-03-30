require "deck"

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
    @players.each_with_index do |player, index|
      player.start_round_in_position(index + 1)
    end
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

