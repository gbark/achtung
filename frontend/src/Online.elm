module Online where


import Maybe exposing (..)
import Input exposing (Input)
import Game exposing (..)


update : Input -> Game -> Game
update ({keys, delta, gamearea, time, server} as input) ({players, state, round} as game) =
    let 
        state' =
            state

        players' =
            -- merge serverInput with predictive result from updatePlayers
            server.players

        round' =
            server.round

    in
        { game | players = players'
               , gamearea = server.gamearea
               , state = state'
               , round = round'
        }
        
       