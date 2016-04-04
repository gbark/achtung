module Output where


import Input exposing (Input)
import Player exposing (..)
import Game exposing (Game)


type alias PlayerOutput =  { direction: String
                           , sequence: Int
                           }


makePlayerOutput : Input -> Game -> PlayerOutput
makePlayerOutput { keys } { sequence } =
    { direction = makeDirection keys
    , sequence = sequence
    }
        
        
makeDirection keys =
    case toDirection keys defaultPlayer of
        Straight ->
            "Straight"
            
        Left ->
            "Left"
        
        Right ->
            "Right"