module Main where


import Html exposing (Html)
import Set exposing (Set)
import Result
import Json.Decode as Json


import View exposing (view)
import Input exposing (..)
import Game exposing (..)
import Online
import Local
import Output exposing (..)
import Decoder 


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
            if Set.member 79 input.keys then
                -- Key 'O' pressed
                { game | mode = Online }
            
            else if Set.member 76 input.keys then
                -- Key 'L' pressed
                { game | mode = Local }
        
            else
                game
            
        Local ->
            Local.update input game
        
        Online ->
            Online.update input game    
        

input : Signal Input
input =
    Signal.map5 Input keyboard delta gamearea time (Decoder.decode serverInput)
        |> Signal.sampleOn delta
        |> Signal.dropRepeats
        
        
-- Ports
        
        
port playerOutput : Signal PlayerOutput
port playerOutput =
    Signal.map makePlayerOutput input 
        |> Signal.dropRepeats
        
        
port onlineGame : Signal Bool
port onlineGame =
    Signal.map (.mode >> (==) Game.Online) gameState
        |> Signal.dropRepeats
        
             
port serverInput : Signal Json.Value