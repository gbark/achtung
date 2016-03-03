module Online where


import Input exposing (Input)
import Game exposing (..)
import Player exposing (..)


update : Input -> Game -> Game
update ({keys, gamearea, clock, server} as input) ({players, state, round} as game) =
    let 
        state' =
            state

        players' =
            players
            -- merge serverInput with predictive result from updatePlayers
            -- updatePlayers input game server state

        round' =
            server.round

    in
        { game | players = players'
               , gamearea = server.gamearea
               , state = state'
               , round = round'
        }
        

updatePlayers : Input -> Game -> Game -> State -> List Player
updatePlayers {keys, gamearea, clock, server} {players, state} serverInput nextState =
    if nextState == Play && state == Play then
        List.map (updatePlayer clock.delta gamearea players)
            (mapInputs players keys)
            
    else
        server.players
        