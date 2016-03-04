module Online where


import Input exposing (Input)
import Game exposing (..)
import Player exposing (..)


update : Input -> Game -> Game
update ({keys, gamearea, clock, server, serverId} as input) ({players, state, round} as game) =
    let 
        players' =
            server.players
            -- merge serverInput with predictive result from updatePlayers
            -- updatePlayers input game server state
            

    in
        { game | players = players'
               , gamearea = server.gamearea
               , state = server.state
               , round = server.round
        }
        

updatePlayers : Input -> Game -> Game -> State -> List Player
updatePlayers {keys, gamearea, clock, server} {players, state} serverInput nextState =
    if nextState == Play && state == Play then
        List.map (updatePlayer clock.delta gamearea players)
            (mapInputs players keys)
            
    else
        server.players
        