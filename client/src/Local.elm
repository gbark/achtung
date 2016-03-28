module Local where


import Color
import Char
import Random
import Set
import String
import List exposing (..)


import Game exposing (..)
import Player exposing (..)
import Input exposing (Input)
import Position exposing (..)


player2 : Player
player2 =
    { defaultPlayer | id = "2"
                    , color = Color.rgb 229 49 39
                    , leftKey = 40
                    , rightKey = 39
                    , keyDesc = "UP,DN"
    }


player3 : Player
player3 =
    { defaultPlayer | id = "3"
                    , color = Color.rgb 25 100 183
                    , leftKey = (Char.toCode 'N')
                    , rightKey = (Char.toCode 'M')
                    , keyDesc = "N,M"
    }


update : Input -> Game -> Game
update input ({players, state, round} as game) =
    let
        state' =
            updateState input game

        players' =
            updatePlayers input game state'

        round' =
            if state == Play && state' == Roundover then
                round + 1

            else
                round

    in
        { game | players = players'
               , gamearea = input.gamearea
               , state = state'
               , round = round'
        }


updateState : Input -> Game -> State
updateState {keys} {players, state} =
    case state of
        Select ->
            if (playerSelect keys) /= Nothing then
                Start

            else
                Select

        Start ->
            if space keys then
                Play

            else
                Start

        Play ->
            if filter .alive players |> isEmpty then
                Roundover

            else
                Play

        Roundover ->
            if space keys then
                Play

            else
                Roundover

        WaitingPlayers ->
            Select

        Connecting ->
            Select

        Cooldown ->
            Select

        CooldownOver ->
            Select


updatePlayers : Input -> Game -> State -> List Player
updatePlayers {keys, clock, gamearea} {players, state} nextState =
    case nextState of
        Select ->
            players

        Start ->
            if state == Select then
                case (playerSelect keys) of
                    Just n ->
                        if n == 1 then
                            [defaultPlayer]

                        else if n == 2 then
                            [defaultPlayer, player2]

                        else if n == 3 then
                            [defaultPlayer, player2, player3]

                        else
                            []

                    Nothing ->
                        players

            else
                players

        Play ->
            case state of
                Select ->
                    map (updatePlayer clock.delta gamearea players)
                    (mapInputs players keys)

                Start ->
                    map (initPlayer gamearea clock.time) players

                Play ->
                    map (updatePlayer clock.delta gamearea players)
                    (mapInputs players keys)

                Roundover ->
                    -- Reset score when playing single player mode
                    if length players == 1 then
                        map resetScore players |> map (initPlayer gamearea clock.time)

                    else
                        map (initPlayer gamearea clock.time) players
                        
                WaitingPlayers ->
                    map (updatePlayer clock.delta gamearea players)
                    (mapInputs players keys)
                        
                Connecting ->
                    map (updatePlayer clock.delta gamearea players)
                    (mapInputs players keys)
                        
                Cooldown ->
                    map (updatePlayer clock.delta gamearea players)
                    (mapInputs players keys)
                        
                CooldownOver ->
                    map (updatePlayer clock.delta gamearea players)
                    (mapInputs players keys)

        Roundover ->
            players

        WaitingPlayers ->
            players

        Connecting ->
            players

        Cooldown ->
            players

        CooldownOver ->
            players


initPlayer : (Int, Int) -> Float -> Player -> Player
initPlayer gamearea time player =
    let
        idInt = 
            Result.withDefault 0 (String.toInt player.id)
            
        seed = 
            (truncate time) + idInt ^ 3

    in
        { player | angle = randomAngle seed
                 , path = [Visible (randomPosition seed gamearea)]
                 , alive = True
        }
        
        
playerSelect : Set.Set Char.KeyCode -> Maybe Int
playerSelect keys =
    if Set.member 49 keys then
        Just 1

    else if Set.member 50 keys then
        Just 2

    else if Set.member 51 keys then
        Just 3

    else
        Nothing


resetScore : Player -> Player
resetScore p =
    { p | score = 0 }