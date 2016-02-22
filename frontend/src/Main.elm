module Main where


import Html exposing (Html)


import View exposing (view)
import Input exposing (Input, input)
import Game exposing (Game, defaultGame)
import Online
import Local


main : Signal Html
main =
    Signal.map view gameState


gameState : Signal Game
gameState =
    Signal.foldp update defaultGame (input defaultGame)



update : Input -> Game -> Game
update input game =
    if game.mode == Game.Local then
        Local.update input game

    else
        Online.update input game