module Output where


import Input exposing (Input)
import Player exposing (..)


type alias PlayerOutput =  { direction: String
                           }


makePlayerOutput : Input -> PlayerOutput
makePlayerOutput {keys} =
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
        }