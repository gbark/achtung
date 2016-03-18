module Decoder where

import Json.Decode as Json exposing (..)
import Json.Decode as Json exposing (..)
import Color
import Char
import Player exposing (..)
import Game exposing (GameLight, defaultGameLight, State)
import Position exposing (..)


decode : Signal Json.Value -> Signal GameLight
decode json = 
    Signal.map fromResult (Signal.map (decodeValue game) json)
    
    
fromResult result =
    case result of
        Ok value ->
            value
        
        Err msg ->
            defaultGameLight


game : Decoder GameLight
game =
    object5 GameLight
        ("players" := list player)
        (maybe ("state" := string `andThen` state))
        (maybe ("gamearea" := tuple2 (,) int int))
        (maybe ("round" := int))
        ("serverTime" := float)
        
        
state : String -> Decoder State
state s =
    case s of
        "Select" -> succeed Game.Select
        "Start" -> succeed Game.Start
        "Play" -> succeed Game.Play
        "Roundover" -> succeed Game.Roundover
        "WaitingPlayers" -> succeed Game.WaitingPlayers
        _ -> fail (s ++ " is not a State")
        
        
mode : String -> Decoder Game.Mode
mode s =
    case s of
        "Undecided" -> succeed Game.Undecided
        "Local" -> succeed Game.Local
        "Online" -> succeed Game.Online
        _ -> fail (s ++ " is not a Mode")
    

player : Decoder PlayerLight
player =
    map PlayerLight ("id" := string)
        `apply` ("lastPositions" := list position)
        `apply` (maybe ("angle" := float))
        `apply` (maybe ("alive" := bool))
        `apply` (maybe ("score" := int))
        `apply` (maybe ("color" := string `andThen` color))
        

apply : Decoder (a -> b) -> Decoder a -> Decoder b
apply func value =
    object2 (<|) func value

        
position : Decoder (Position (Float, Float))
position =
    ("visible" := bool) `andThen` visibility
    
            
visibility : Bool -> Decoder (Position (Float, Float))
visibility visible =
    if visible then
        object2 (\x y -> Visible (x, y))
            ("x" := float)
            ("y" := float)
                
    else
        object2 (\x y -> Hidden (x, y))
            ("x" := float)
            ("y" := float)
            

direction : String -> Decoder Direction
direction s =
    case s of
        "Straight" -> succeed Straight
        "Left" -> succeed Left
        "Right" -> succeed Right
        _ -> fail (s ++ " is not a Direction")


color : String -> Decoder Color.Color
color s =
    case s of 
        "red" -> succeed Color.red
        "orange" -> succeed Color.orange
        "yellow" -> succeed Color.yellow
        "green" -> succeed Color.green
        "blue" -> succeed Color.blue
        "purple" -> succeed Color.purple
        "brown" -> succeed Color.brown
        "white" -> succeed Color.white
        "grey" -> succeed Color.grey
        _ -> fail (s ++ " is not a supported color")

