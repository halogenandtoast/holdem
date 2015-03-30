class Card < Struct.new(:suit, :value)
  SUITS = %w(S H C D)
  VALUES = 1..13
end
