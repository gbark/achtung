module Online where


import Input exposing (Input)
import Game exposing (..)
import Player exposing (..)
import Position exposing (..)
import Color
import Array
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
    { game |  --players = updatePlayers input game
        --    , players = [player''] ++ opponents'
            players = players
            , gamearea = withDefault gamearea server.gamearea 
            , state = withDefault state server.state 
            , round = withDefault round server.round 
            , serverTime = server.serverTime
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
                    
        state = 
            game.state
        
        updates = 
            game.serverTime /= input.server.serverTime
            
        serverPlayers =
            if updates then
                List.map resetPlayerLight input.server.players
            
            else
                input.server.players
                    
    in
        if nextState == Play then
            if state == Roundover || state == WaitingPlayers then
                let players' = List.map resetPlayer game.players in
                List.map (syncPlayer players' updates) serverPlayers
            
            else
                List.map (syncPlayer game.players updates) serverPlayers
            
        else 
            List.map (syncPlayer game.players updates) serverPlayers
                

syncPlayer : List Player -> Bool -> PlayerLight -> Player
syncPlayer players stale playerLight =
    let 
        player = 
            Maybe.withDefault defaultPlayer <| List.head <| List.filter (.id >> (==) playerLight.id) players
            
        path' =
            if player.pathBuffer /= playerLight.pathBuffer && not stale then
                player.path -- playerLight.pathBuffer ++ player.path
                
            else
                player.path
        
    in
        { player | id = playerLight.id
                 , path = path'
                 , angle = withDefault player.angle playerLight.angle
                 , alive = withDefault player.alive playerLight.alive
                 , score = withDefault player.score playerLight.score
                 , color = withDefault player.color playerLight.color 
                 , pathBuffer = playerLight.pathBuffer
                 }


resetPlayer player =
    { player | path = defaultPlayer.path
             , pathBuffer = defaultPlayer.pathBuffer
             }


resetPlayerLight player =
    { player | pathBuffer = Array.empty }
    
    
-- Clear positions from old rounds.
cleanBuffer positions pathBuffer round =
    List.filter (.round >> (==) round) (pathBuffer ++ positions)
    
    
-- Pop real(s) from pathBuffer.
-- If no real(s) found, create a fake. 
-- If fake was created, push to front of path and pathBuffer. 
-- == End of fake tree ==
-- If real(s) found, then find the oldest fake(s) in path and replace with real(s). 
--      (( If we have more real(s) than fakes+1, then dont push them to path, but push them to pathBuffer. ))
-- For each fake replaced, pop one from pathBuffer.
-- If no fake needs to be replaced, push real to front.
-- If positions were replaced, then push one fake. 
-- Always need to return path with +1 length
updatePathAndBuffer player =
    let 
        reals = 
            Array.filter ((==) Real) player.pathBuffer
            
        fakes = 
            Array.filter ((==) Fake) player.pathBuffer
            
    in
        if Array.isEmpty reals then
            noReals reals fakes player
        
        else if Array.length reals > Array.length fakes then
            realsAreGreater reals fakes player
            
        else if not (Array.isEmpty reals) then
            realsAreLess reals fakes player
                            
        else 
            realsAndFakesAreSame reals fakes player
                                
            
noReals reals fakes ({ pathBuffer } as player) =
    let 
        fake = 
            getFake 
            
        path' =
            [asPosition fake] ++ player.path
            
        pathBuffer' =
            [fake] ++ fakes 
            
    in
        { player | path = path' 
                 , pathBuffer = pathBuffer'
                 }
             
    
realsAreGreater reals fakes ({ pathBuffer } as player) =
    let
        realsLength =
            Array.length reals
            
        fakesLength =
            Array.length fakes
            
        diff = 
            realsLength - fakesLength
            
        path' =
            (List.map asPosition <| List.drop diff reals) ++ (List.drop fakesLength player.path)
            
        pathBuffer' =
            List.take diff reals
            
    in
        { player | path = path'
                 , pathBuffer = pathBuffer' 
                 }
                
                
realsAreLess reals fakes ({ pathBuffer } as player) =
    let 
        realsLength =
            Array.length reals
            
        fakesLength =
            Array.length fakes
            
        diff = 
            fakesLength - realsLength
    
        newFakes = 
            List.map (\_ -> getFake) [0..diff-1] 
        
        path' = 
            (List.map asPosition newFakes) 
            ++ (List.map asPosition reals) 
            ++ (List.drop diff (List.take fakesLength player.path)) -- Correct? Before refactor: ++ (List.drop pathFakes diff) 
            ++ (List.drop fakesLength player.path)
        
        pathBuffer' =
            newFakes ++ (Array.slice 0 -(realsLength) pathBuffer)  
            
    in
        { player | path = path'
                 , pathBuffer = pathBuffer' 
                 }
                
                
realsAndFakesAreSame reals fakes ({ pathBuffer } as player) = 
    let 
        fake = 
            getFake 
            
        path' =
            [asPosition fake] ++ (List.map asPosition reals) ++ (List.drop (Array.length fakes) player.path) 
            
        pathBuffer' =
            [fake] ++ (Array.slice 0 -(Array.length reals) pathBuffer) 
            
    in
        { player | path = path'
                 , pathBuffer = pathBuffer'
                 }
                    
                    
-- getFake position angle delta =
getFake =
    Fake (Visible (0, 0))
    


asPosition p =
    case p of 
        Real x -> x
        Fake x -> x
