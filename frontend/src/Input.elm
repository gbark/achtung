module Input where


import Time exposing (..)
import Set 
import Char
import Keyboard
import Window


import Config
import Game exposing (Game, State)
import Player exposing (PlayerLight)


type alias Input =
    { keys: Set.Set Char.KeyCode
    , delta: Time.Time
    , gamearea: (Int, Int)
    , time: Time.Time
    , serverInput: Maybe ServerInput
    }
    
    
type alias ServerInput =
    { players: List PlayerLight
    , round: Int
    , state: String
    }
    

delta : Signal Time
delta =
    Signal.map inSeconds (fps 35)
    

time : Signal Time
time =
    (every millisecond)
    

keyboard : Signal (Set.Set Char.KeyCode)
keyboard =
    Keyboard.keysDown


gamearea : Signal (Int, Int)
gamearea =
    (Signal.map (\(w, h) -> (w-Config.sidebarWidth-Config.sidebarBorderWidth, h)) Window.dimensions)
    