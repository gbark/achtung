module Decoder where

import Json.Decode as Json exposing (..)
import Json.Decode as Json exposing (..)
import Color
import Char
import Player exposing (..)
import Game exposing (..)
import Position exposing (..)


decode : Signal Json.Value -> Signal Game
decode json = 
    Signal.map fromResult (Signal.map (decodeValue game) json)
    
    
fromResult result =
    case result of
        Ok value ->
            value
        
        Err msg ->
            let log = Debug.log "err" msg in
            defaultGame


game : Decoder Game
game =
    object5 Game
        ("players" := list player)
        ("state" := string `andThen` state)
        ("mode" := string `andThen` mode)
        ("gamearea" := tuple2 (,) int int)
        ("round" := int)
        
        
state : String -> Decoder State
state s =
    case s of
        "Select" -> succeed Select
        "Start" -> succeed Start
        "Play" -> succeed Play
        "Roundover" -> succeed Roundover
        "WaitingPlayers" -> succeed WaitingPlayers
        _ -> fail (s ++ " is not a State")
        
        
mode : String -> Decoder Mode
mode s =
    case s of
        "Undecided" -> succeed Undecided
        "Local" -> succeed Local
        "Online" -> succeed Online
        _ -> fail (s ++ " is not a Mode")
        

player : Decoder Player
player =
    map Player ("id" := string)
        `apply` ("path" := list position)
        `apply` ("angle" := float)
        `apply` ("direction" := string `andThen` direction)
        `apply` ("alive" := bool)
        `apply` ("score" := int)
        `apply` ("color" := string `andThen` color)
        `apply` ("leftKey" := key)
        `apply` ("rightKey" := key)
        `apply` ("keyDesc" := string)
        


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


key : Decoder Char.KeyCode
key =
    succeed (Char.toCode 'P')
    
    