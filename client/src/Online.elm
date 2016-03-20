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
    -- let 
        -- playerId =
        --     Maybe.withDefault "id-missing" serverId
    
        -- player = 
        --     List.head <| List.filter (.id >> (==) playerId) server.players

        -- player' = 
        --     syncPlayer players player

        -- player'' = 
        --     updatePlayer clock.delta gamearea [player] <| mapInput player' keys
            
        -- opponents =
        --     -- server.players 
        --     List.filter (.id >> (/=) playerId) server.players
            
        -- opponents' =
        --     List.map (syncPlayer players) opponents
    
    -- in
    { game | players = updatePlayers input game
        --    , players = [player''] ++ opponents'
            , gamearea = withDefault gamearea server.gamearea 
            , state = withDefault state server.state 
            , round = withDefault round server.round 
    }


updatePlayers : Input -> Game -> List Player
updatePlayers input game =
    let 
        nextState =
            case input.server.state of
                Just state -> 
                    state
                
                Nothing ->
                    game.state
                    
    in
        case nextState of
            Select ->
                List.map (syncPlayer game.players) input.server.players
    
            Start ->
                List.map (syncPlayer game.players) input.server.players
    
            Play ->
                if game.state == Roundover || game.state == WaitingPlayers then
                    let players' = List.map resetPlayer game.players in
                    List.map (syncPlayer players') input.server.players
                
                else
                    List.map (syncPlayer game.players) input.server.players
    
            Roundover ->
                List.map (syncPlayer game.players) input.server.players
    
            WaitingPlayers ->
                List.map (syncPlayer game.players) input.server.players
                

syncPlayer : List Player -> PlayerLight -> Player
syncPlayer players playerLight =
    let 
        player = 
            Maybe.withDefault defaultPlayer <| List.head <| List.filter (.id >> (==) playerLight.id) players
            
        path' =
            if player.lastPositions /= playerLight.lastPositions then
                player.path ++ playerLight.lastPositions
                
            else
                player.path
        
    in
        { player | id = playerLight.id
                 , path = path'
                 , angle = withDefault player.angle playerLight.angle
                 , alive = withDefault player.alive playerLight.alive
                 , score = withDefault player.score playerLight.score
                 , color = withDefault player.color playerLight.color 
                 , lastPositions = playerLight.lastPositions
                 }


resetPlayer : Player -> Player
resetPlayer player =
    { player | path = defaultPlayer.path
             , lastPositions = defaultPlayer.lastPositions
             , angle = defaultPlayer.angle
             }