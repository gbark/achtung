module Input where


import Time exposing (..)
import Set 
import Char
import Keyboard
import Window


import Config
import Game exposing (Game)


type alias Input =
    { keys: Set.Set Char.KeyCode
    , delta: Time.Time
    , gamearea: (Int, Int)
    , time: Time.Time
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


input : Signal Input
input =
    Signal.map4 Input keyboard delta gamearea time
        |> Signal.sampleOn delta
        |> Signal.dropRepeats
