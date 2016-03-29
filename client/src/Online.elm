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
        if nextState == Play && state /= Play then
            let 
                players' = 
                    List.map resetPlayer game.players 
                    
            in
                List.map (syncPlayer stale clock.delta nextState players') server.players
            
        else 
            List.map (syncPlayer stale clock.delta nextState game.players) server.players
         
         
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
                

syncPlayer : Bool -> Float -> State -> List Player -> PlayerLight -> Player
syncPlayer stale delta state players playerLight =
    let 
        player = 
            Maybe.withDefault defaultPlayer <| List.head <| List.filter (.id >> (==) playerLight.id) players
            
        player' =
            syncBuffers player playerLight stale
            
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
             , angle = defaultPlayer.angle
             , direction = defaultPlayer.direction
             }
             

syncBuffers player server stale =
    case stale of
        True ->
            player
            
        False ->
            { player | pathBuffer = Array.append server.pathBuffer player.pathBuffer }
    
    
updatePathAndBuffer delta player =
    let 
        actuals = 
            Array.filter (not << isPrediction) player.pathBuffer
            
        predictions =
            Array.filter isPrediction player.pathBuffer
            
    in
        if Array.isEmpty actuals then
            appendPrediction predictions delta player
        
        else if Array.length actuals > Array.length predictions then
            appendActuals actuals predictions player
            
        else if not (Array.isEmpty actuals) then
            appendActualsAndPadWithPredictions actuals predictions delta player
                            
        else 
            appendActualsAndPadWithPrediction actuals predictions delta player
                                

-- Add one prediction to path and pathBuffer
appendPrediction : Array PositionOnline -> Float -> Player -> Player
appendPrediction predictions delta ({ pathBuffer } as player) =
    let 
        log = Debug.log "appendPrediction" True
        
        prediction = 
            case player.path of 
                [] -> 
                    Prediction (Hidden (0, 0))
                
                p :: ps ->
                    generatePrediction delta player.angle p
            
        path' =
            [asPosition prediction] ++ player.path
            
        pathBuffer' =
            Array.append (Array.fromList [prediction]) predictions 
            
    in
        if List.isEmpty player.path then
            player
            
        else
            { player | path = path'
                     , pathBuffer = pathBuffer'
                     }

-- Replace any predictions on path with actual positions and add an actual position on top. 
-- All actual positions, minus one, which have no prediction to replace should be saved in pathBuffer. The left
-- over actual position should be added to path.
appendActuals : Array PositionOnline -> Array PositionOnline -> Player -> Player  
appendActuals actuals predictions player =
    let
        log = Debug.log "appendActuals" True
        
        actualsLength =
            Array.length actuals
            
        predictionsLength =
            Array.length predictions
            
        diff = 
            actualsLength - predictionsLength
            
        actuals' =
            Array.toList actuals
            
        path =
            (List.map asPosition <| List.drop (diff - 1) actuals') ++ (List.drop predictionsLength player.path)
            
        pathBuffer =
            Array.fromList <| List.take (diff - 1) actuals'
            
    in
        { player | path = path
                 , pathBuffer = pathBuffer
                 }
                
-- Replace as many predictions as possible with actual positions. Clear pathBuffer of replaced and generate
-- new predictions to replace out of date predictions. 
appendActualsAndPadWithPredictions : Array PositionOnline -> Array PositionOnline -> Float -> Player -> Player
appendActualsAndPadWithPredictions actuals predictions delta ({ pathBuffer } as player) =
    let 
        log = Debug.log "appendActualsAndPadWithPredictions" True
    
        actualsLength =
            Array.length actuals
            
        predictionsLength =
            Array.length predictions
            
        diff = 
            predictionsLength - actualsLength
            
        seed = 
            withDefault (Prediction (Hidden (0, 0))) (List.head actuals')
    
        newPredictions = 
            generatePredictions delta player.angle diff seed
            
        actuals' =
            Array.toList actuals
        
        path = 
               (List.map asPosition newPredictions) 
            ++ (List.map asPosition actuals')
            ++ (List.drop diff (List.take predictionsLength player.path)) 
            ++ (List.drop predictionsLength player.path)
        
        pathBuffer' =
            Array.append (Array.fromList newPredictions) (Array.slice 0 -(actualsLength) pathBuffer)  
            
    in
        { player | path = path
                 , pathBuffer = pathBuffer' 
                 }

-- Replace as many predictions as possible with actual positions. Clear pathBuffer and generate
-- new predictions to replace out of date predictions. Generate one prediction to pad path.
appendActualsAndPadWithPrediction : Array PositionOnline -> Array PositionOnline -> Float -> Player -> Player
appendActualsAndPadWithPrediction actuals predictions delta player = 
    let 
        log = Debug.log "appendActualsAndPadWithPrediction" True
        
        actuals' =
            Array.map asPosition actuals
        
        prediction = 
            case Array.toList <| Array.slice 0 1 actuals' of 
                [] -> 
                    Prediction (Hidden (0, 0))
                
                p :: ps ->
                    generatePrediction delta player.angle p
            
        path' =
            [asPosition prediction] ++ (Array.toList actuals') ++ (List.drop (Array.length predictions) player.path) 
            
        pathBuffer =
            Array.fromList [prediction] 
            
    in
        { player | path = path'
                 , pathBuffer = pathBuffer
                 }
                    
                    
generatePrediction delta angle seedPosition =
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
                Prediction (Hidden (0, 0))
                
            p :: ps ->
                Prediction p 


generatePredictions delta angle n seedPosition =
    List.foldl (\_ acc -> 
        case acc of 
            [] ->
                []
            
            p :: ps ->
                (generatePrediction delta angle (asPosition p)) :: p :: ps
                
    ) [seedPosition] <| List.repeat n 0


asPosition : PositionOnline -> Position (Float, Float)
asPosition p =
    case p of 
        Actual x -> x
        Prediction x -> x
        

isPrediction p =
    case p of 
        Prediction _ -> True
        Actual _ -> False
