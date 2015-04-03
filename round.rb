require "deck"
require "pry"

class Round
  def initialize(players, options = {})
    @deck = Deck.build.shuffle
    @players = players
    @players.each(&:reset)

    @table = {
      small_blind: options[:small_blind],
      big_blind: options[:big_blind],
      raise_amount: options[:big_blind],
      pot: 0,
      flop: [],
      turn: [],
      river: [],
      events: [],
      bids: [],
      sidepots: []
    }
  end

  def play
    @players.each_with_index do |player, index|
      player.start_round_in_position(index + 1)
    end
    deal_hole
    small_blind
    big_blind
    get_choices(2)

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
    determine_winner(players, players.reject(&:out?), table[:pot], table[:sidepots])
  end

  def big_blind
    begin
      player = @players.reject(&:eliminated?)[1]
      player.big_blind(table)
      puts "Big blind from #{player.name}: #{player.bid}"
    rescue Exception => e
      binding.pry
      puts e
      raise
    end
  end

  def small_blind
    begin
      player = @players.reject(&:eliminated?)[0]
      player.small_blind(table)
      puts "Small blind from #{player.name}: #{player.bid}"
    rescue Exception => e
      binding.pry
      puts e
    end
  end

  def has_winner?
    @players.reject(&:out?).count == 1
  end

  def get_choices(offset = 0)
    begin
      while @players.select(&:can_bid?).count > 1
        @players.select(&:can_bid?)[offset..-1].each do |player|
          choice = player.get_choice(@table)
          case choice
          when "FOLD"
            @table[:events] << "#{player.name} FOLDED"
            if has_winner?
              setup_sidepots
              return
            end
            if @players.select(&:can_bid?).map(&:bid).uniq.count == 1
              setup_sidepots
              return
            end
          when "CALL"
            @table[:events] << "#{player.name} CALLED"
            if @players.select(&:can_bid?).map(&:bid).uniq.count == 1
              setup_sidepots
              return
            end
          when "RAISE"
            @table[:events] << "#{player.name} RAISED"
          end
        end
        offset = 0
      end

      setup_sidepots
      @table[:bids] = []
    rescue Exception => e
      binding.pry
      puts e
      raise
    end
  end

  def setup_sidepots
    if @players.any?(&:all_in)
      all_in = @players.select(&:all_in).sort_by(&:bid)
      all_in_amount = all_in.first.bid
      all_in.each do |player|
        if player.sidepots == 0
          new_all_in_amount = @table[:pot] + @players.reject(&:eliminated?).map { |o| [o.bid, player.bid].min }.reduce(:+)
          if new_all_in_amount != all_in_amount
            table[:sidepots] << all_in_amount
          end
          player.sidepots = table[:sidepots].length
        end
      end
    end
  end

  def declare_winner
    puts "DECLARING WINNER"
    winner = @players.find { |player| !player.out? }
    winner.money += @table[:pot]

    @players.each do |player|
      player.round_over(winner)
    end
    puts(@players.map { |player| player.as_json([]) })
    puts "#{winner.name} wins"
    puts "DECLARED WINNER"
  end

  def determine_winner(players, showdown_players, pot, sidepots, sidepot = false, cleanup = true)
    puts "DETERMING WINNER"
    begin
      hands = showdown_players.map { |player| player.best_hand(table_cards) }
      scores = hands.each_with_index.map { |hand, i| [i, HandScorer.new(hand).score] }
      winner_index = scores.sort_by { |x| x[1] }.last[0]
      winner = showdown_players[winner_index]

      if winner.all_in
        puts "AWARDING SIDEPOT to #{winner.name}"
        amount = sidepots[0,winner.sidepots].reduce(:+)
        puts "#{amount} out of #{pot} awarded"
        winner.money += amount
        pot -= amount
        winner.sidepot(pot)

        winner.sidepots.times { |i| sidepots[i] = 0 }
        if pot > 0
          determine_winner(players, showdown_players - [winner], pot, sidepots, true, false)
        end
      else
        if sidepot
          puts "remaining #{pot} awarded to #{winner.name}"
          winner.sidepot(pot)
        end
        winner.money += pot
      end

      if cleanup
        table[:pot] = 0

        @players.reject(&:eliminated?).each do |player|
          if player.money == 0
            player.eliminated = true
          end
        end

        @players.each do |player|
          player.showdown(winner, showdown_players, @players)
        end
        puts(@players.map { |player| player.as_json([]) })
        puts "#{winner.name} wins"
      end
    rescue Exception => e
      puts e
      binding.pry
      raise
    end
    puts "DETERMINED WINNER"
  end

  def deal_hole
    puts "Dealing hole"
    @players.reject(&:eliminated?).each do |player|
      hole = @deck.pop(2)
      player.deal(hole)
      puts "Dealt 2 cards to #{player.name}"
    end
  end

  def deal_flop
    puts "Dealing flop"
    @table[:flop] += @deck.pop(3)
  end

  def deal_turn
    puts "Dealing turn"
    @table[:turn] = @deck.pop(1)
  end

  def deal_river
    puts "Dealing river"
    @table[:river] = @deck.pop(1)
  end

  def table_cards
    @table[:flop] + @table[:turn] + @table[:river]
  end

  private

  attr_reader :table, :players
end

