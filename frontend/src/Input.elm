module Input where


import Time exposing (..)
import Set 
import Char
import Keyboard
import Window


import Consts
import Game exposing (Game)


type alias Input =
    { keys: Set.Set Char.KeyCode
    , delta: Time.Time
    , gamearea: (Int, Int)
    , time: Time.Time
    , socketStatus: String
    }
    

delta : Signal Time
delta =
    Signal.map inSeconds (fps 35)


input : Game -> Signal Input
input game =
    Signal.sampleOn delta <|
        Signal.map5 Input
            Keyboard.keysDown
            delta
            (Signal.map (\(w, h) -> (w-Consts.sidebarWidth-Consts.sidebarBorderWidth, h)) Window.dimensions)
            (every millisecond)
            received.signal


everConnected : Signal Bool
everConnected =
    Signal.foldp (||) False connected.signal


connectionStatus : Signal String
connectionStatus =
    let f : (Bool, Bool) -> String
        f tup = case tup of
            (False, False) -> "Connecting..."
            (False, True) -> "Disconnected."
            (True, _) -> "Connected."
    in Signal.map2 (\a b -> f (a,b)) connected.signal everConnected


-- MAILBOXES


connected : Signal.Mailbox Bool
connected =
    Signal.mailbox False


received : Signal.Mailbox String
received =
    Signal.mailbox "null"
