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

    if has_winner?
      declare_winner
      return
    end

    deal_flop
    get_choices
    if has_winner?
      declare_winner
      return
    end

    deal_turn
    get_choices
    if has_winner?
      declare_winner
      return
    end

    deal_river
    get_choices
    determine_winner
  end

  def has_winner?
    @players.reject(&:eliminated?).count == 1
  end

  def get_choices
    @players.reject(&:eliminated?).each do |player|
      choice = player.get_choice(@table)
      case choice
      when "FOLD"
        @table[:events] << "#{player.name} FOLDED"
        if has_winner?
          return
        end
      when "CALL"
        @table[:events] << "#{player.name} CALLED"
      when "RAISE"
        @table[:events] << "#{player.name} RAISED"
      end
    end
  end

  def declare_winner
    winner = @players.find { |player| !player.eliminated? }
    @players.each do |player|
      player.round_over(winner)
    end
  end

  def determine_winner
    showdown_players = players.reject(&:eliminated?)
    hands = showdown_players.map { |player| player.best_hand(table_cards) }
    scores = hands.each_with_index.map { |hand, i| [i, HandScorer(hand).score] }
    winner_index = scores.sort_by { |x| x[1] }.last[0]
    winner = showdown_players[winner_index]
    @players.each do |player|
      player.showdown(winner, showdown_players, @players)
    end
  end

  def deal_hole
    puts "Dealing hole"
    @players.each do |player|
      hole = @deck.pop(2)
      @hands[player] << hole
      player.deal(hole)
    end
  end

  def deal_flop
    @table[:flop] += @deck.pop(3)
  end

  def deal_turn
    @table[:turn] = @deck.pop(1)
  end

  def deal_river
    @table[:river] = @deck.pop(1)
  end

  def table_cards
    @table[:flop] + @table[:turn] + @table[:river]
  end
end

