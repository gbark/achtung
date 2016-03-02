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
    , delta: Time.Time
    , gamearea: (Int, Int)
    , time: Time.Time
    , server: Game
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
    
    
-- convertServerInput : ServerInput -> Input
-- convertServerInput serverInput =
--     { serverInput | players = (List.map convertPlayers serverInput.players)
--     } 
    
    
-- convertPlayers player =
--     { player | id = 99
--              , path = (List.map convertPath player.path)
--              , color = Color.rgb 254 221 3
--              , leftKey = (Char.toCode 'O')
--              , leftKey = (Char.toCode 'P')
--              , keyDesc = "O,P"
--              }
             
             
-- convertPath : Map -> Position (Float, Float)
-- convertPath path =
--     Position Hidden (path.x, path.y)