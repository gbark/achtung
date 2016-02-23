module Game where


import Player exposing (Player)


type State = Select
           | Start
           | Play
           | Roundover


type Mode = Undecided | Local | Online


type alias Game =
    { players: List Player
    , state: State
    , mode: Mode
    , gamearea: (Int, Int)
    , round: Int
    }
    

defaultGame : Game
defaultGame =
    { players = []
    , state = Select
    , mode = Undecided
    , gamearea = (0, 0)
    , round = 0
    }