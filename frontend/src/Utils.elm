module Utils where


import Position exposing (..)


isVisible : Position (Float, Float) -> Bool
isVisible position =
    case position of
        Visible _ -> True
        Hidden _ -> False


asXY : Position (Float, Float) -> (Float, Float)
asXY position =
    case position of
        Visible (x, y) -> (x, y)
        Hidden (x, y) -> (x, y)