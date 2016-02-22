module Game where


import Player exposing (Player)


type State = Select
           | Start
           | Play
           | Roundover


type Mode = Local | Online


type alias Game =
    { players: List Player
    , state: State
    , mode: Mode
    , gamearea: (Int, Int)
    , round: Int
    , socketStatus: String
    }
    

defaultGame : Game
defaultGame =
    { players = []
    , state = Select
    , mode = Local
    , gamearea = (0, 0)
    , round = 0
    , socketStatus = "Unknown"
    }