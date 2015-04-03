class Card < Struct.new(:suit, :value)
  SUITS = %w(S H C D)
  VALUES = %w(2 3 4 5 6 7 8 9 T J Q K A)
end
