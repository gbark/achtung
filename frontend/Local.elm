module Local where


import Color
import Char
import Random
import List exposing (..)
import Time exposing (..)


import Model exposing (..)
import Shared exposing (..)


player2 : Player
player2 =
    { defaultPlayer | id = 2
              , color = Color.rgb 229 49 39
              , leftKey = 40
              , rightKey = 39
              , keyDesc = "UP,DN"
    }


player3 : Player
player3 =
    { defaultPlayer | id = 3
              , color = Color.rgb 25 100 183
              , leftKey = (Char.toCode 'N')
              , rightKey = (Char.toCode 'M')
              , keyDesc = "N,M"
    }


update : Input -> Game -> Game
update ({keys, delta, gamearea, time, socketStatus} as input) ({players, state, round} as game) =
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
               , gamearea = gamearea
               , state = state'
               , round = round'
               , socketStatus = socketStatus
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


updatePlayers : Input -> Game -> State -> List Player
updatePlayers {keys, delta, gamearea, time} {players, state} nextState =
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
                    map (updatePlayer delta gamearea time players)
                    (mapInputs players keys)

                Start ->
                    map (initPlayer gamearea time) players

                Play ->
                    map (updatePlayer delta gamearea time players)
                    (mapInputs players keys)

                Roundover ->
                    -- Reset score when playing single player mode
                    if length players == 1 then
                        map resetScore players |> map (initPlayer gamearea time)

                    else
                        map (initPlayer gamearea time) players

        Roundover ->
            players


initPlayer : (Int, Int) -> Time -> Player -> Player
initPlayer gamearea time player =
    let
        seed = (truncate (inMilliseconds time)) + player.id ^ 3

    in
        { player | angle = randomAngle seed
                 , path = [Visible (randomPosition seed gamearea)]
                 , alive = True
        }