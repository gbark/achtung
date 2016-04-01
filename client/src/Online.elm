module Online where

import Set
import Char
import Color
import Array exposing (Array)
import Maybe exposing (withDefault)

import Input exposing (Input)
import Game exposing (..)
import Player exposing (..)
import Position exposing (..)
import Utils exposing (..)


update : Input -> Game -> Game
update ({ gamearea, server, serverId } as input) game =
    case serverId of
        Nothing ->
            game
            
        Just id ->
            let 
                tickObject =
                    makeTickObject input game id
                    
                opponents =
                    List.map (updateOpponent tickObject) (snd tickObject.serverPlayers)
                    
                self =
                    updateSelf tickObject
                    
            in
                { game | players = self ++ opponents
                       , state = tickObject.nextState
                       , gamearea = withDefault gamearea server.gamearea 
                       , round = withDefault game.round server.round
                       , serverTime = server.serverTime
                       }
           
           
updateSelf { state, nextState, delta, keys, localPlayers, serverPlayers } =
    case fst serverPlayers of
        Nothing ->
            []
            
        Just serverPlayer ->
            let 
                localPlayer = 
                    Maybe.withDefault defaultPlayer (fst localPlayers)
                    |> resetAtNewRound state nextState
                    |> seedPath serverPlayer
                    |> setAngle serverPlayer
                    |> mapInput keys
                            
            in
                if nextState == Play then
                    [move delta False localPlayer]
                        
                else
                    [localPlayer]
            

updateOpponent : TickObject -> PlayerLight -> Player
updateOpponent { stale, delta, nextState, state, localPlayers } serverOpponent =
    let 
        localOpponent = 
            List.filter (.id >> (==) serverOpponent.id) (snd localPlayers)
            |> List.head 
            |> Maybe.withDefault defaultPlayer
            |> resetAtNewRound state nextState
            |> syncBuffers serverOpponent stale
            |> updatePathAndBuffer nextState delta
        
    in
        { localOpponent | id = serverOpponent.id
                        , angle = withDefault localOpponent.angle serverOpponent.angle
                        , alive = withDefault localOpponent.alive serverOpponent.alive
                        , score = withDefault localOpponent.score serverOpponent.score
                        , color = withDefault localOpponent.color serverOpponent.color 
                        }
    
    
updatePathAndBuffer nextState delta player =
    case nextState == Play of
        False ->
            player
            
        True ->
            let 
                actuals = 
                    Array.filter (isPrediction >> not) player.pathBuffer
                    
                predictions =
                    Array.filter isPrediction player.pathBuffer
                    
            in
                if Array.isEmpty actuals then
                    appendActualsAndPadWithPrediction actuals predictions delta player
                
                else if Array.length actuals > Array.length predictions then
                    appendActuals actuals predictions player
                    
                else if not (Array.isEmpty actuals) then
                    appendActualsAndPadWithPredictions actuals predictions delta player
                                    
                else 
                    appendActualsAndPadWithPrediction actuals predictions delta player
         

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
               (List.map asPosition <| List.drop (diff - 1) actuals') 
            ++ (List.drop predictionsLength player.path)
            
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
            
        actuals' =
            Array.toList actuals
            
        seed = 
            withDefault (Prediction (Hidden (0, 0))) (List.head actuals')
    
        newPredictions = 
            generatePredictions delta player.angle diff seed
        
        path = 
               (List.map asPosition newPredictions) 
            ++ (List.map asPosition actuals')
            ++ (List.drop diff <| List.take predictionsLength player.path)
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
        
        predictions' =
            if Array.isEmpty actuals then
                predictions
            
            else
                Array.empty
            
        predictionsLength =
            Array.length predictions'
        
        actuals' =
            Array.toList <| Array.map asPosition actuals
        
        newPrediction = 
            case actuals' of 
                [] -> 
                    Prediction (Hidden (0, 0))
                
                p :: ps ->
                    generatePrediction delta player.angle p
            
        path' =
               [asPosition newPrediction] 
            ++ actuals'
            ++ (List.drop predictionsLength player.path) 
            
        pathBuffer =
            Array.append (Array.fromList [newPrediction]) predictions
            
    in
        { player | path = path'
                 , pathBuffer = pathBuffer
                 }
                    
                    
generatePrediction delta angle seedPosition =
    let 
        mockPlayer =
            { defaultPlayer | path = [seedPosition]
                            , angle = angle
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
                      

seedPath serverPlayer localPlayer =
    case localPlayer.path of
        [] ->
            { localPlayer | path = Array.toList <| Array.map asPosition serverPlayer.pathBuffer }
            
        x :: xs ->
            localPlayer
            
            
setAngle serverPlayer localPlayer =
    if localPlayer.angle == defaultPlayer.angle then
        case serverPlayer.angle of
            Just angle -> 
                { localPlayer | angle = angle }
                
            Nothing ->
                localPlayer

    else
        localPlayer


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


resetAtNewRound state nextState player =
    case nextState == Play && state /= Play of
        True ->
            { player | path = defaultPlayer.path
                     , pathBuffer = defaultPlayer.pathBuffer
                     , angle = defaultPlayer.angle
                     , direction = defaultPlayer.direction
                     }
        
        False ->
            player
    
             

syncBuffers server stale player =
    case stale of
        True ->
            player
            
        False ->
            { player | pathBuffer = Array.append server.pathBuffer player.pathBuffer }


asPosition : PositionOnline -> Position (Float, Float)
asPosition p =
    case p of 
        Actual x -> x
        Prediction x -> x
        

isPrediction p =
    case p of 
        Prediction _ -> True
        Actual _ -> False


type alias TickObject = { state: State
                        , nextState: State
                        , delta: Float
                        , keys: Set.Set Char.KeyCode
                        , stale: Bool
                        , localPlayers: (Maybe Player, List Player)
                        , serverPlayers: (Maybe PlayerLight, List PlayerLight)
                        }
           

makeTickObject : Input -> Game -> String -> TickObject
makeTickObject { clock, server, keys } { state, serverTime, players } id =
    TickObject 
        state
        (case server.state of
            Just serverState -> 
                serverState
            
            Nothing ->
                state)
        clock.delta
        keys
        (isStale serverTime server.serverTime)
        (List.partition (.id >> (==) id) players |> \x -> (List.head (fst x), snd x))
        (List.partition (.id >> (==) id) server.players |> \x -> (List.head (fst x), snd x))
