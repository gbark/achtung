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
update ({ gamearea, clock, server, serverId, keys } as input) game =
    case serverId of
        Nothing ->
            game
            
        Just id ->
            let 
                nextState =
                    case server.state of
                        Just serverState -> 
                            serverState
                        
                        Nothing ->
                            game.state
                            
                stale = 
                    isStale game.serverTime server.serverTime
                            
                (localPlayer, localOpponents) = 
                    List.partition (.id >> (==) id) game.players
                            
                (serverPlayer, serverOpponents) = 
                    List.partition (.id >> (==) id) server.players
                    
                player =
                    case List.head serverPlayer of
                        Nothing ->
                            []
                            
                        Just serverPlayer' ->
                            [updateSelf game.state nextState clock.delta keys (List.head localPlayer) serverPlayer']
                    
                opponents =
                    updateOpponents game.state nextState clock.delta stale localOpponents serverOpponents
                    
            in
                { game | players = player ++ opponents
                       , state = nextState
                       , gamearea = withDefault gamearea server.gamearea 
                       , round = withDefault game.round server.round
                       , serverTime = server.serverTime
                       }
           
           
updateSelf state nextState delta keys localPlayer serverPlayer =
    let 
        localPlayer' = 
            Maybe.withDefault defaultPlayer localPlayer
            
        localPlayer'' = 
            case nextState == Play && state /= Play of
                True ->
                    resetPlayer localPlayer' 
                
                False ->
                    localPlayer'
                    
    in
        if nextState == Play then
            syncSelf localPlayer'' serverPlayer
                |> mapInput keys
                |> move delta False
                
        else
            syncSelf localPlayer'' serverPlayer


syncSelf : Player -> PlayerLight -> Player
syncSelf localPlayer serverPlayer =
    let 
        -- Set initial position based on server data
        path =
            case localPlayer.path of
                [] ->
                    Array.toList <| Array.map asPosition serverPlayer.pathBuffer
                
                x :: xs ->
                    localPlayer.path
                    
        -- Set initial angle based on server data
        angle =
            if localPlayer.angle == defaultPlayer.angle then
                case serverPlayer.angle of
                    Just angle -> 
                        angle
                        
                    Nothing ->
                        defaultPlayer.angle

            else
                localPlayer.angle
                
        
    in
        { localPlayer | id = serverPlayer.id
                      , path = path
                      , angle = angle 
                      , alive = withDefault localPlayer.alive serverPlayer.alive
                      , score = withDefault localPlayer.score serverPlayer.score
                      , color = withDefault localPlayer.color serverPlayer.color 
                      }


updateOpponents state nextState delta stale localOpponents serverOpponents =
    let 
        localOpponents' = 
            case nextState == Play && state /= Play of
                True ->
                    List.map resetPlayer localOpponents 
                
                False ->
                    localOpponents
    
    in
        List.map (syncOpponents stale delta nextState localOpponents') serverOpponents
         
         
isStale previousServerTime serverTime = 
    case serverTime of
        Nothing ->
            True
            
        Just st ->
            case previousServerTime of 
                Nothing ->
                    False
                    
                Just lt -> 
                    if st > lt then
                        False
                        
                    else
                        True
                

syncOpponents : Bool -> Float -> State -> List Player -> PlayerLight -> Player
syncOpponents stale delta nextState localOpponents serverOpponent =
    let 
        localOpponent = 
            Maybe.withDefault defaultPlayer <| List.head <| List.filter (.id >> (==) serverOpponent.id) localOpponents
            
        localOpponent' =
            syncBuffers localOpponent serverOpponent stale
            
        { path, pathBuffer } =
            if nextState == Play then
                updatePathAndBuffer delta localOpponent'
                
            else
                localOpponent'
        
    in
        { localOpponent | id = serverOpponent.id
                        , path = path
                        , angle = withDefault localOpponent.angle serverOpponent.angle
                        , alive = withDefault localOpponent.alive serverOpponent.alive
                        , score = withDefault localOpponent.score serverOpponent.score
                        , color = withDefault localOpponent.color serverOpponent.color 
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
        -- log = Debug.log "appendPrediction" True
        
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
        -- log = Debug.log "appendActuals" True
        
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
        -- log = Debug.log "appendActualsAndPadWithPredictions" True
    
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
        -- log = Debug.log "appendActualsAndPadWithPrediction" True
        
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
