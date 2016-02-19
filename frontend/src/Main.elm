module Main where


import Window
import Keyboard
import List exposing (..)
-- import SocketIO
import Task exposing (Task, andThen)
import Html exposing (..)
import Time exposing (..)


-- import Protocol exposing (..)
import Shared exposing (..)
import Model exposing (..)
import Utils exposing (..)
import View exposing (..)
import Online
import Local


defaultGame : Game
defaultGame =
    { players = []
    , state = Select
    , mode = Local
    , gamearea = (0, 0)
    , round = 0
    , socketStatus = "Unknown"
    }


-- UPDATE


update : Input -> Game -> Game
update input game =
    if game.mode == Local then
        Local.update input game

    else
        Online.update input game


-- SIGNALS


main : Signal Html
main =
    Signal.map view gameState


gameState : Signal Game
gameState =
    Signal.foldp update defaultGame (input defaultGame)


delta : Signal Time
delta =
    Signal.map inSeconds (fps 35)


input : Game -> Signal Input
input game =
    Signal.sampleOn delta <|
        Signal.map5 Input
            Keyboard.keysDown
            delta
            (Signal.map (\(w, h) -> (w-sidebarWidth-sidebarBorderWidth, h)) Window.dimensions)
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


-- WEBSOCKET


-- port initial : Task x ()
-- port initial =
--     socket `andThen` SocketIO.emit "pingo" "pingo"


-- port connection : Task x ()
-- port connection =
--     socket `andThen` SocketIO.connected connected.address


-- port responses : Task x ()
-- port responses =
--     socket `andThen` SocketIO.on "pong" received.address
