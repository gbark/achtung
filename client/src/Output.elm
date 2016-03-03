module Output where


import Input exposing (Input)
import Player exposing (..)


type alias PlayerOutput =  { direction: String, localTime: Float }


makePlayerOutput : Input -> PlayerOutput
makePlayerOutput {keys, clock} =
    let 
        directionString =
            case toDirection keys defaultPlayer of
                Straight ->
                    "Straight"
                    
                Left ->
                    "Left"
                
                Right ->
                    "Right"

    in
        { direction = directionString
        , localTime = clock.time
        }