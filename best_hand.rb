require "hand_scorer"

class BestHand
  def initialize(cards)
    @cards = cards
  end

  def determine
    @determine ||=
      begin
        hands = combinations
        scores = hands.each_with_index.map { |hand, i| [i, HandScorer.new(hand).score] }
        winner = scores.sort_by { |x| x[1] }.last[0]
        hands[winner]
      end
  end

  private

  attr_reader :cards

  def combinations
    @combinations ||= cards.combination(5).to_a
  end
end
