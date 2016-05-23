module Online where

import Set
import Char
import Color
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
                    
                -- log = Debug.log "sequence" game.sequence
                    
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
                    
                -- log = Debug.log "self path length" (List.length localPlayer'.path)
                            
            in
                if nextState == Play then
                    [move delta False localPlayer']
                        
                else
                    [localPlayer']
            

updateOpponent : TickObject -> PlayerLight -> Player
updateOpponent { stale, delta, nextState, state, localPlayers } serverOpponent =
    List.filter (.id >> (==) serverOpponent.id) (snd localPlayers)
        |> List.head 
        |> Maybe.withDefault defaultPlayer
        |> resetAtNewRound state nextState
        |> mergeWithDefaults serverOpponent
        |> updatePathAndBuffer serverOpponent state nextState delta stale

    -- log = Debug.log "opponent path length" (List.length localOpponent.path)
                        
mergeWithDefaults serverOpponent localOpponent =
    { localOpponent | id = serverOpponent.id
                    , angle = withDefault localOpponent.angle serverOpponent.angle
                    , alive = withDefault localOpponent.alive serverOpponent.alive
                    , score = withDefault localOpponent.score serverOpponent.score
                    , color = withDefault localOpponent.color serverOpponent.color 
                    }


resetAtNewRound state nextState player =
    case nextState == Play && state /= Play of
        True ->
            let log = Debug.log ("path" ++ (toString player.id)) player.path in
                { player | path = defaultPlayer.path
                        , predictedPositions = defaultPlayer.predictedPositions
                        , angle = defaultPlayer.angle
                        , direction = defaultPlayer.direction
                        }
        
        False ->
            player
    
    
updatePathAndBuffer { latestPositions } state nextState delta stale player = 
    let latestPositions' = 
        if stale then 
            [] 
            
        else 
            latestPositions
            
    in  
        if nextState == Play && player.alive then
            let 
                newPredictions = 
                    if (List.length latestPositions') > player.predictedPositions then 
                        []
                        
                    else if (List.length latestPositions') == player.predictedPositions then
                        makePredictions (List.head latestPositions') delta 1 player
                        
                    else 
                        makePredictions (List.head latestPositions') delta (player.predictedPositions + 1) player
                    
                -- log = Debug.log ("newPredictions: " ++ (toString (List.length newPredictions)) ++ " latestPositions': " ++ (toString (List.length latestPositions'))) True  
            
                path =
                    newPredictions                                           -- Append new predictions
                    ++ latestPositions'                                      -- Append positions recieved from server
                    ++ (List.drop player.predictedPositions player.path)     -- Remove old predictions               
                    
            in
                { player | path = path
                         , predictedPositions = List.length newPredictions
                         }
        else 
            { player | path = latestPositions ++ (List.drop player.predictedPositions player.path)
                     , predictedPositions = 0
                     }            
                 
                 
makePredictions seed delta diff player =
    case seed of 
        Nothing -> 
            case player.path of
                [] ->
                    []
                    
                p :: _ ->
                    List.foldr (predictionCombiner delta player.angle p) [] <| List.repeat 1 0
        
        Just p ->
            List.foldr (predictionCombiner delta player.angle p) [] <| List.repeat diff 0
                

predictionCombiner delta angle seed _ acc =
    case acc of 
        [] ->
            case generatePrediction delta angle seed of
                Nothing ->
                    acc
                
                Just prediction ->
                    prediction :: acc
        
        p :: _ ->
            case generatePrediction delta angle p of
                Nothing ->
                    acc
                
                Just prediction ->
                    prediction :: acc

                    
generatePrediction delta angle seed =
    let 
        mockPlayer =
            { defaultPlayer | path = [seed]
                            , angle = angle
                            }
        
        { path } = 
            move delta False mockPlayer
            
    in 
        case path of 
            [] ->
                Nothing
                
            p :: ps ->
                Just p
                      

setInitialPath serverPlayer localPlayer =
    case List.isEmpty localPlayer.path of
        True ->
            { localPlayer | path = serverPlayer.latestPositions }
            
        False ->
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
                    
                Just pst -> 
                    if st > pst then
                        False
                        
                    else
                        True


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
