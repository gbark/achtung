module Online where


import Input exposing (Input)
import Game exposing (..)
import Player exposing (..)
import Position exposing (..)
import Color
import Array exposing (Array)
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
           , gamearea = withDefault gamearea server.gamearea 
           , state = withDefault state server.state
           , round = withDefault round server.round
           , serverTime = server.serverTime
    }


updatePlayers : Input -> Game -> List Player
updatePlayers { server, clock } game =
    let 
        nextState =
            case server.state of
                Just state -> 
                    state
                
                Nothing ->
                    game.state
                    
        state = 
            game.state
        
        stale = 
            isStale game.serverTime server.serverTime
                    
    in
        if nextState == Play then
            if state == Roundover || state == WaitingPlayers || state == Cooldown || state == CooldownOver then
                let 
                    players' = 
                        List.map resetPlayer game.players 
                        
                in
                    List.map (syncPlayer players' stale clock.delta nextState) server.players
            
            else
                List.map (syncPlayer game.players stale clock.delta nextState) server.players
            
        else 
            List.map (syncPlayer game.players stale clock.delta nextState) server.players
         
         
isStale lastTime serverTime = 
    case serverTime of
        Nothing ->
            True
            
        Just st ->
            case lastTime of 
                Nothing ->
                    False
                    
                Just lt -> 
                    if st > lt then
                        False
                        
                    else
                        True
                

syncPlayer : List Player -> Bool -> Float -> State -> PlayerLight -> Player
syncPlayer players stale delta state playerLight =
    let 
        player = 
            Maybe.withDefault defaultPlayer <| List.head <| List.filter (.id >> (==) playerLight.id) players
            
        player' =
            syncBuffers player playerLight stale state
            
        { path, pathBuffer } =
            if state == Play then
                updatePathAndBuffer delta player'
                
            else
                player'
        
    in
        { player | id = playerLight.id
                 , path = path
                 , angle = withDefault player.angle playerLight.angle
                 , alive = withDefault player.alive playerLight.alive
                 , score = withDefault player.score playerLight.score
                 , color = withDefault player.color playerLight.color 
                 , pathBuffer = pathBuffer
                 }


resetPlayer player =
    { player | path = defaultPlayer.path
             , pathBuffer = defaultPlayer.pathBuffer
             }
             

syncBuffers player server stale state =
    case stale of
        True ->
            player
            
        False ->
            if state /= Play then
                { player | pathBuffer = Array.empty }
                
            else 
                { player | pathBuffer = Array.append server.pathBuffer player.pathBuffer }
    
    
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
updatePathAndBuffer delta player =
    let 
        reals = 
            Array.filter (not << isFake) player.pathBuffer
            
        fakes =
            Array.filter isFake player.pathBuffer
            
    in
        if Array.isEmpty reals then
            appendFake fakes delta player
        
        else if Array.length reals > Array.length fakes then
            appendReals reals fakes player
            
        else if not (Array.isEmpty reals) then
            appendRealsAndPadWithFakes reals fakes delta player
                            
        else 
            appendRealsAndPadWithFake reals fakes delta player
                                

-- Add one fake to path and pathBuffer
appendFake : Array PositionOnline -> Float -> Player -> Player
appendFake fakes delta ({ pathBuffer } as player) =
    let 
        log = Debug.log "appendFake" True
        
        fake = 
            case player.path of 
                [] -> 
                    Fake (Hidden (0, 0))
                
                p :: ps ->
                    getFake delta player.angle p
            
        path' =
            [asPosition fake] ++ player.path
            
        pathBuffer' =
            Array.append (Array.fromList [fake]) fakes 
            
    in
        if List.isEmpty player.path then
            player
            
        else
            { player | path = path'
                     , pathBuffer = pathBuffer'
                     }

-- Replace any fakes on path with reals and add one real on top. 
-- All reals, minus one, which have no fake to replace should be saved in pathBuffer. The left
-- over real should be added to path.
appendReals : Array PositionOnline -> Array PositionOnline -> Player -> Player  
appendReals reals fakes player =
    let
        log = Debug.log "appendReals" True
        
        realsLength =
            Array.length reals
            
        fakesLength =
            Array.length fakes
            
        diff = 
            realsLength - fakesLength
            
        reals' =
            Array.toList reals
            
        path =
            (List.map asPosition <| List.drop (diff - 1) reals') ++ (List.drop fakesLength player.path)
            
        pathBuffer =
            Array.fromList <| List.take (diff - 1) reals'
            
    in
        { player | path = path
                 , pathBuffer = pathBuffer
                 }
                
-- Replace as many fakes as possible with reals. Clear pathBuffer of replaced and generate
-- new fakes to replace out of date fakes. 
appendRealsAndPadWithFakes : Array PositionOnline -> Array PositionOnline -> Float -> Player -> Player
appendRealsAndPadWithFakes reals fakes delta ({ pathBuffer } as player) =
    let 
        log = Debug.log "appendRealsAndPadWithFakes" True
    
        realsLength =
            Array.length reals
            
        fakesLength =
            Array.length fakes
            
        diff = 
            fakesLength - realsLength
            
        seed = 
            withDefault (Fake (Hidden (0, 0))) (List.head reals')
    
        newFakes = 
            getFakes delta player.angle diff seed
            
        reals' =
            Array.toList reals
        
        path = 
               (List.map asPosition newFakes) 
            ++ (List.map asPosition reals')
            ++ (List.drop diff (List.take fakesLength player.path)) -- Correct? Before refactor: ++ (List.drop pathFakes diff) 
            ++ (List.drop fakesLength player.path)
        
        pathBuffer' =
            Array.append (Array.fromList newFakes) (Array.slice 0 -(realsLength) pathBuffer)  
            
    in
        { player | path = path
                 , pathBuffer = pathBuffer' 
                 }

-- Replace as many fakes as possible with reals. Clear pathBuffer and generate
-- new fakes to replace out of date fakes. Generate one fake to pad path.
appendRealsAndPadWithFake : Array PositionOnline -> Array PositionOnline -> Float -> Player -> Player
appendRealsAndPadWithFake reals fakes delta player = 
    let 
        log = Debug.log "appendRealsAndPadWithFake" True
        
        reals' =
            Array.map asPosition reals
        
        fake = 
            case Array.toList <| Array.slice 0 1 reals' of 
                [] -> 
                    Fake (Hidden (0, 0))
                
                p :: ps ->
                    getFake delta player.angle p
            
        path' =
            [asPosition fake] ++ (Array.toList reals') ++ (List.drop (Array.length fakes) player.path) 
            
        pathBuffer =
            Array.fromList [fake] 
            
    in
        { player | path = path'
                 , pathBuffer = pathBuffer
                 }
                    
                    
getFake delta angle seedPosition =
    let 
        mockPlayer =
            { defaultPlayer | path = [seedPosition]
                            , angle = angle
                            , direction = Straight
                            }
        
        { path } = 
            move delta False mockPlayer
            
    in 
        case path of 
            [] ->
                Fake (Hidden (0, 0))
                
            p :: ps ->
                Fake p 


getFakes delta angle n seedPosition =
    List.foldl (\_ acc -> 
        case acc of 
            [] ->
                []
            
            p :: ps ->
                (getFake delta angle (asPosition p)) :: p :: ps
                
    ) [seedPosition] <| List.repeat n 0


asPosition : PositionOnline -> Position (Float, Float)
asPosition p =
    case p of 
        Real x -> x
        Fake x -> x
        

isFake p =
    case p of 
        Fake _ -> True
        Real _ -> False