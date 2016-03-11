module Game where


import Player exposing (Player, PlayerLight)


type State = Select
           | Start
           | Play
           | Roundover
           | WaitingPlayers


type Mode = Undecided | Local | Online


type alias Game =
    { players: List Player
    , state: State
    , mode: Mode
    , gamearea: (Int, Int)
    , round: Int
    }


-- Light weight Game object for sending over the wire
type alias GameLight =
    { players: List PlayerLight
    , state: Maybe State
    , gamearea: Maybe (Int, Int)
    , round: Maybe Int
    }
    

defaultGame : Game
defaultGame =
    { players = []
    , state = Select
    , mode = Undecided
    , gamearea = (0, 0)
    , round = 0
    }
    

defaultGameLight : GameLight
defaultGameLight =
    { players = []
    , state = Just WaitingPlayers
    , gamearea = Just (0, 0)
    , round = Just 0
    }
    