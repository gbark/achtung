module Online where


import Input exposing (Input)
import Game exposing (..)
import Player exposing (..)
import Position exposing (..)
import Color
import Maybe exposing (withDefault)
import Utils exposing (..)


update : Input -> Game -> Game
update ({keys, gamearea, clock, server, serverId} as input) ({players, state, round} as game) =
    let 
        playerId =
            Maybe.withDefault "id-missing" serverId
    
        player = 
            Maybe.withDefault defaultPlayer (List.head (List.filter (.id >> (==) playerId) players))
    
        player' = 
            { player | color = Color.lightBlue }
    
        -- player' = 
        --     updatePlayer clock.delta gamearea (opponents ++ [player]) (mapInput player' keys)   
    
        serverOpponents = 
            List.filter (.id >> (/=) playerId) server.players 
    
        localOpponents = 
            List.filter (.id >> (/=) playerId) players
            
        opponents =
            List.map (syncPlayer localOpponents) serverOpponents
            
        player'' = 
            updatePlayer clock.delta gamearea (opponents ++ [player']) (mapInput player' keys)   
            
    in
        { game | players = (opponents ++ [player''])
               , gamearea = withDefault game.gamearea server.gamearea 
               , state = withDefault game.state server.state 
               , round = withDefault game.round server.round 
        }
                

syncPlayer : List Player -> PlayerLight -> Player
syncPlayer players playerLight =
    let 
        player = 
            Maybe.withDefault defaultPlayer (List.head (List.filter (.id >> (==) playerLight.id) players))
            
        path' =
            if player.lastPositions /= playerLight.lastPositions then
                player.path ++ playerLight.lastPositions
                
            else
                player.path
        
    in
        { player | path = path'
                 , angle = withDefault player.angle playerLight.angle
                 , alive = withDefault player.alive playerLight.alive
                 , score = withDefault player.score playerLight.score
                 , color = withDefault player.color playerLight.color 
                 , lastPositions = playerLight.lastPositions
                 }
                 
            
-- fresh : List (Position (Float, Float)) -> List (Position (Float, Float)) -> Bool
-- fresh ps1 ps2 = 
--     let 
--         head1 =
--             asXY (Maybe.withDefault (Visible (0,0)) (List.head ps1))
            
--         head2 =
--             asXY (Maybe.withDefault (Visible (0,0)) (List.head ps2))
            
--     in
--         fst head1 == fst head2 && snd head1 == snd head2