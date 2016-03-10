module Online where


import Input exposing (Input)
import Game exposing (..)
import Player exposing (..)
import Color


update : Input -> Game -> Game
update ({keys, gamearea, clock, server, serverId} as input) ({players, state, round} as game) =
    let 
        serverIdString =
            Maybe.withDefault "0" serverId
    
        playerLocal = 
            Maybe.withDefault defaultPlayer (List.head (List.filter (.id >> (==) serverIdString) players))
    
        opponents = 
            List.filter (.id >> (/=) serverIdString) server.players
    
        playerLocal' = 
            { playerLocal | color = Color.purple }
    
        playerLocal'' = 
            updatePlayer clock.delta gamearea (List.concat [opponents, [playerLocal']]) (mapInput playerLocal' keys)
    
        players' =
            List.concat [opponents, [playerLocal'']]
            -- merge serverInput with predictive result from updatePlayers
            -- updatePlayers input game server state
            

    in
        { game | players = players'
               , gamearea = server.gamearea
               , state = server.state
               , round = server.round
        }
        

updatePlayers : Input -> State -> List Player -> List Player
updatePlayers {keys, gamearea, clock} state players =
    if state == Play then
        List.map (updatePlayer clock.delta gamearea players)
            (mapInputs players keys)
            
    else
        players
        