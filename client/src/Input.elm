module Input where


import Time exposing (..)
import Set 
import Char
import Keyboard
import Window
import Color


import Config
import Game exposing (Game, State)
import Player exposing (PlayerLight)
import Position exposing (..)


type alias Input =
    { keys: Set.Set Char.KeyCode
    , gamearea: (Int, Int)
    , clock: Clock
    , server: Game
    , serverId: Maybe String
    }
    
    
type alias Clock =
    { delta : Float
    , time : Float
    }
    

clock : Signal Clock
clock =
    Signal.map (\(time, delta) -> { time = time, delta = (inSeconds delta) }) (timestamp ((fps 35)))
        

keyboard : Signal (Set.Set Char.KeyCode)
keyboard =
    Keyboard.keysDown


gamearea : Signal (Int, Int)
gamearea =
    (Signal.map (\(w, h) -> (w-Config.sidebarWidth-Config.sidebarBorderWidth, h)) Window.dimensions)
    