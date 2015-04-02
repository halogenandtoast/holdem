class HandScorer
  def initialize(hand)
    @hand = hand
  end

  def score
    ranks = '23456789TJQKA'
    rcounts = hand.each_with_object({}) { |a, hash| hash[ranks.index(a[0])] = hand.join.count(a[0]) }.to_a
    score = rcounts.map { |a, b| [b, a] }.sort.reverse.map(&:first)
    ranks = rcounts.map { |a, b| [b, a] }.sort.reverse.map(&:last)
    if score.size == 5
      if ranks[0,2] == [12, 3]
        ranks = [3, 2, 1, 0, -1]
      end
      straight = ranks[0] - ranks[4] == 4
      flush = hand.map { |a| a[1] }.uniq.count == 1
      score = [[[1], [3,1,1,1]], [[3,1,1,2], [5]]][flush ? 1: 0][straight ? 1 : 0]
    end
    [score, ranks]
  end

  private

  attr_reader :hand
end
