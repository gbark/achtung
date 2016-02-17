module Online where


import Model exposing (..)


update : Input -> Game -> Game
update ({keys, delta, gamearea, time, socketStatus} as input) ({players, state, round} as game) =
    let
        state' =
            state
            -- updateState input game

        players' =
            players
            -- updatePlayers input game state'

        round' =
            round
            -- if state == Play && state' == Roundover then
            --     round + 1

            -- else
            --     round

    in
        { game | players = players'
               , gamearea = gamearea
               , state = state'
               , round = round'
               , socketStatus = socketStatus
        }