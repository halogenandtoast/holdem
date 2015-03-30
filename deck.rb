require "card"

class Deck
  def self.build
    Card::SUITS.flat_map do |suit|
      Card::VALUES.map do |value|
        Card.new(suit, value)
      end
    end
  end
end
