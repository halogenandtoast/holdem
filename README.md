# Texas Hold'em API Competition

## API Details

### Format details

    <card> format is a string "AH", "TC", "2S", etc.
    <type> is "raise", "fold", "call"
    <player_event> is { type: <type>, player: <player>, bid: current_bid_amount } a raise type will include amount: x if limit is false in "game_start" event
    <player> = if player was in showdown
                 { name: name, in_showdown: true, hand: [<card>, <card>], money: n, best_hand: [<card>, <card>, <card>, <card>, <card>] }
               otherwise
                 { name: name, in_showdown: false, money: n }

### Event

    { event: "get_name" } # client should puts name
    { event: "game_start", money: 1000, number_of_players: 4, small_blind: 1, big_blind: 2, limit: bool } # limit is randomly assigned
    { event: "big_blind", amount: n }
    { event: "small_blind", amount: n }
    { event: "round_start", position: 1} # position 1 is player after the dealer and dealer will have the highest position
    { event: "choice", table: {
      betting_round: 1 # up to 4
      pot: 0,
      flop: [(<card>, <card>, <card>)?], #either empty of three cards
      turn: [<card>?], # either an array of a single card or empty
      river: [<card>?], # either an array of a single card of empty
      events: [(<player_event>, ...)?], # zero or more player events
      bids: [{ name: name, position: 1, amount: amount}]
    } }

    { event: "time_out" } # automatically fold
    { event: "invalid_command" } # automatically fold, closes connection, happens when you issue a command out of turn or an invalid choice

    { event: "hole", cards: [<card>, <card>] } # will contain two cards

    { event: "round_over", winner: <player>, pot: n }
    { event: "showdown", winner: <player>, players: [<player>, ...]}
    { event: "sidepot", amount: n } # If an all in player wins, sidepots will be assigned
    { event: "game_over", winner: <player>, won: bool } # won informs you if you are the winner
