module Model where


import Color
import Char
import Set
import Time


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


type alias Player =
    { id: Int
    , path: List (Position (Float, Float))
    , angle: Float
    , direction: Direction
    , alive: Bool
    , score: Int
    , color: Color.Color
    , leftKey: Char.KeyCode
    , rightKey: Char.KeyCode
    , keyDesc: String
    }


type alias Input =
    { keys: Set.Set Char.KeyCode
    , delta: Time.Time
    , gamearea: (Int, Int)
    , time: Time.Time
    , socketStatus: String
    }


type Direction
    = Left
    | Right
    | Straight


type Position a = Visible a | Hidden a