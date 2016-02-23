module Main where


import Html exposing (Html)
import Set exposing (Set)


import View exposing (view)
import Input exposing (Input, input)
import Game exposing (..)
import Online
import Local
import Output exposing (..)


main : Signal Html
main =
    Signal.map view gameState


gameState : Signal Game
gameState =
    Signal.foldp update defaultGame input



update : Input -> Game -> Game
update input game =
    case game.mode of 
        Undecided -> 
            if Set.member 49 input.keys then
                -- Numerical 1 pressed
                { game | mode = Online }
            
            else if Set.member 50 input.keys then
                -- Numerical 2 pressed
                { game | mode = Local }
        
            else
                game
            
        Local ->
            Local.update input game
        
        Online ->
            Online.update input game    
        
        
port playerOutput : Signal PlayerOutput
port playerOutput =
    Signal.map makePlayerOutput input 
        |> Signal.dropRepeats
        
        
port onlineGame : Signal Bool
port onlineGame =
    Signal.map (.mode >> (==) Game.Online) gameState
        |> Signal.dropRepeats
        