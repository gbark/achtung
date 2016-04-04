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
                    
                sequence =
                    updateSequence tickObject game.sequence
                    
                log = Debug.log "sequence" game.sequence
                    
            in
                { game | players = self ++ opponents
                       , state = tickObject.nextState
                       , gamearea = withDefault gamearea server.gamearea 
                       , round = withDefault game.round server.round
                       , serverTime = server.serverTime
                       , sequence = sequence
                       }


updateSequence { state, nextState } sequence =
    if nextState == Play && state /= Play then 
        0 
        
    else if nextState == Play then
        sequence + 1
        
    else
        sequence

           
updateSelf { state, nextState, delta, keys, localPlayers, serverPlayers } =
    case fst serverPlayers of
        Nothing ->
            []
            
        Just serverPlayer ->
            let 
                localPlayer =
                    Maybe.withDefault defaultPlayer (fst localPlayers)
                    
                localPlayer' = 
                    { localPlayer | id = serverPlayer.id
                                  , alive = withDefault localPlayer.alive serverPlayer.alive
                                  , score = withDefault localPlayer.score serverPlayer.score
                                  , color = withDefault localPlayer.color serverPlayer.color 
                                  }
                    |> resetAtNewRound state nextState
                    |> setInitialPath serverPlayer
                    |> setInitialAngle serverPlayer
                    |> mapInput keys                
                    
                log = Debug.log "self path length" (List.length localPlayer'.path)
                            
            in
                if nextState == Play then
                    [move delta False localPlayer']
                        
                else
                    [localPlayer']
            

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
            
        log = Debug.log "opponent path length" (List.length localOpponent.path)
        
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
                freshPositions = 
                    Array.filter (isPrediction >> not) player.pathBuffer
                    |> Array.toList 
                    |> List.map asPosition
                    
                oldPredictions =
                    Array.filter isPrediction player.pathBuffer
                    
            in
                if List.length freshPositions > Array.length oldPredictions then
                    -- We have low latency and are in sync with server. 
                    -- Just append fresh positions received from server and remove any predictions.
                    { player | path = freshPositions ++ (List.drop (Array.length oldPredictions) player.path)
                             , pathBuffer = Array.empty
                             }
                    
                else
                    -- We have some latency and are behind server. Need to predict next position.
                    appendFreshPositionsAndPadWithPredictions freshPositions oldPredictions delta player
                    

appendFreshPositionsAndPadWithPredictions : List (Position ( Float, Float )) -> Array PositionOnline -> Float -> Player -> Player
appendFreshPositionsAndPadWithPredictions freshPositions oldPredictions delta player = 
    let 
        -- log = Debug.log "appendFreshPositionsAndPadWithPredictions" True
        oldPredictionsLength =
            Array.length oldPredictions
            
        diff = 
            oldPredictionsLength - (List.length freshPositions)
            
        newPredictions = 
            case freshPositions of 
                [] -> 
                    case player.path of
                        [] ->
                            []
                            
                        seed :: _ ->
                            generatePredictions delta player.angle 1 seed
                
                seed :: _ ->
                    generatePredictions delta player.angle diff seed
            
        path =
               (List.map asPosition newPredictions) 
            ++ freshPositions
            ++ (List.drop diff <| List.take oldPredictionsLength player.path)
            ++ (List.drop oldPredictionsLength player.path) 
            
    in
        { player | path = path
                 , pathBuffer = makePathBuffer freshPositions newPredictions oldPredictions
                 }


makePathBuffer freshPositions newPredictions oldPredictions =
    case List.isEmpty freshPositions of 
        True ->
            Array.append (Array.fromList newPredictions) oldPredictions
            
        False ->
            Array.fromList newPredictions

                    
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
                Nothing
                
            p :: ps ->
                Just (Prediction p)


generatePredictions delta angle n seedPosition =
    List.foldr (\_ acc ->
        case acc of 
            [] ->
                case generatePrediction delta angle seedPosition of
                    Nothing ->
                        acc
                    
                    Just prediction ->
                        prediction :: acc
            
            p :: _ ->
                case generatePrediction delta angle (asPosition p) of
                    Nothing ->
                        acc
                    
                    Just prediction ->
                        prediction :: acc
                
    ) [] <| List.repeat n 0
                      

setInitialPath serverPlayer localPlayer =
    case localPlayer.path of
        [] ->
            { localPlayer | path = Array.toList <| Array.map asPosition serverPlayer.pathBuffer }
            
        x :: xs ->
            localPlayer
            
            
setInitialAngle serverPlayer localPlayer =
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
                        , sequence: Int
                        }
           

makeTickObject : Input -> Game -> String -> TickObject
makeTickObject { clock, server, keys } { state, serverTime, players, sequence } id =
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
        sequence
