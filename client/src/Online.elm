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
        log2 = Debug.log "server.state" server.state
        nextState =
            case server.state of
                Just state -> 
                    state
                
                Nothing ->
                    game.state
                    
        state = 
            game.state
        
        stale = 
            game.serverTime == server.serverTime
                    
    in
        if nextState == Play then
            if state == Roundover || state == WaitingPlayers then
                let 
                    players' = 
                        List.map resetPlayer game.players 
                        
                in
                    List.map (syncPlayer players' stale clock.delta nextState) server.players
            
            else
                List.map (syncPlayer game.players stale clock.delta nextState) server.players
            
        else 
            List.map (syncPlayer game.players stale clock.delta nextState) server.players
                

syncPlayer : List Player -> Bool -> Float -> State -> PlayerLight -> Player
syncPlayer players stale delta nextState playerLight =
    let 
        player = 
            Maybe.withDefault defaultPlayer <| List.head <| List.filter (.id >> (==) playerLight.id) players
            
        { path, pathBuffer } =
            if not stale && nextState == Play then
                updatePathAndBuffer delta player
                
            else
                player
        
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
            noReals fakes delta player
        
        else if Array.length reals > Array.length fakes then
            realsAreGreater reals fakes player
            
        else if not (Array.isEmpty reals) then
            realsAreLess reals fakes delta player
                            
        else 
            realsAndFakesAreSame reals fakes delta player
                                

noReals : Array PositionOnline -> Float -> Player -> Player
noReals fakes delta ({ pathBuffer } as player) =
    let 
        log = Debug.log "noReals" True
        
        fake = 
            getFake delta player
            
        path' =
            [asPosition fake] ++ player.path
            
        pathBuffer' =
            Array.append (Array.fromList [fake]) fakes 
            
    in
        { player | path = path' 
                 , pathBuffer = pathBuffer'
                 }
             
realsAreGreater : Array PositionOnline -> Array PositionOnline -> Player -> Player  
realsAreGreater reals fakes ({ pathBuffer } as player) =
    let
        log = Debug.log "realsAreGreater" True
        
        realsLength =
            Array.length reals
            
        fakesLength =
            Array.length fakes
            
        diff = 
            realsLength - fakesLength
            
        path' =
            (List.map asPosition <| List.drop diff (Array.toList reals)) ++ (List.drop fakesLength player.path)
            
        pathBuffer' =
            Array.fromList <| List.take diff (Array.toList reals)
            
    in
        { player | path = path'
                 , pathBuffer = pathBuffer' 
                 }
                
             
realsAreLess : Array PositionOnline -> Array PositionOnline -> Float -> Player -> Player
realsAreLess reals fakes delta ({ pathBuffer } as player) =
    let 
        log = Debug.log "realsAreLess" True
    
        realsLength =
            Array.length reals
            
        fakesLength =
            Array.length fakes
            
        diff = 
            fakesLength - realsLength
    
        newFakes = 
            List.repeat diff (getFake delta player)
        
        path' = 
            (List.map asPosition newFakes) 
            ++ (Array.toList (Array.map asPosition reals)) 
            ++ (List.drop diff (List.take fakesLength player.path)) -- Correct? Before refactor: ++ (List.drop pathFakes diff) 
            ++ (List.drop fakesLength player.path)
        
        pathBuffer' =
            Array.append (Array.fromList newFakes) (Array.slice 0 -(realsLength) pathBuffer)  
            
    in
        { player | path = path'
                 , pathBuffer = pathBuffer' 
                 }
                
realsAndFakesAreSame : Array PositionOnline -> Array PositionOnline -> Float -> Player -> Player
realsAndFakesAreSame reals fakes delta ({ pathBuffer } as player) = 
    let 
        log = Debug.log "realsAndFakesAreSame" True
        
        fake = 
            getFake delta player
            
        path' =
            [asPosition fake] ++ (Array.toList (Array.map asPosition reals)) ++ (List.drop (Array.length fakes) player.path) 
            
        pathBuffer' =
            Array.append (Array.fromList [fake]) (Array.slice 0 -(Array.length reals) pathBuffer) 
            
    in
        { player | path = path'
                 , pathBuffer = pathBuffer'
                 }
                    
                    
getFake delta player =
    let 
        { path } = 
            move delta player
            
    in 
        case path of 
            [] ->
                Fake (Hidden (0, 0))
                
            p :: ps ->
                Fake p 
    

asPosition : PositionOnline -> Position (Float, Float)
asPosition p =
    case p of 
        Real x -> x
        Fake x -> x


asXY : Position (Float, Float) -> (Float, Float)
asXY p =
    case p of
        Visible (x, y) -> (x, y)
        Hidden (x, y) -> (x, y)
        

isFake p =
    case p of 
        Fake _ -> True
        Real _ -> False