require "card"

class Deck
  def self.build
    Card::SUITS.flat_map do |suit|
      Card::VALUES.map do |value|
        "#{suit}#{value}"
      end
    end
  end
end
