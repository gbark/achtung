module Shared where


import Color
import Char
import Random
import Set
import List exposing (..)
import Time exposing (..)


import Model exposing (..)
import Utils exposing (..)


maxAngleChange = 5
speed = 125
snakeWidth = 3
sidebarWidth = 250
sidebarBorderWidth = 5


defaultPlayer : Player
defaultPlayer =
    { id = 1
    , path = []
    , angle = 0
    , direction = Straight
    , alive = True
    , score = 0
    , color = Color.rgb 254 221 3
    , leftKey = (Char.toCode 'Z')
    , rightKey = (Char.toCode 'X')
    , keyDesc = "Z,X"
    }


resetScore : Player -> Player
resetScore p =
    { p | score = 0 }


updatePlayer : Time -> (Int, Int) -> Time -> List Player -> Player -> Player
updatePlayer delta gamearea time players player =
    if not player.alive then
        player

    else
        let
            player' =
                move delta player

            position =
                Maybe.withDefault (Visible (0, 0)) (head player'.path)

            paths =
                collisionPaths player' players

            hs =
                any (hitSnake position) paths

            hw =
                hitWall position gamearea

            winner =
                if length players > 1
                && length (filter .alive players) < 2 then
                    True

                else
                    False

        in
            if hs || hw then
                { player' | alive = False }

            else if winner then
                { player' | score = player'.score + 1
                          , alive = False
                }

            -- Single player (survivor mode)
            else if length players == 1 then
                { player' | score = player'.score + 1 }

            else
                player'


collisionPaths player players =
    let
        others =
            filter (.id >> (/=) player.id) players

        otherPaths =
            foldl (.path >> flip append) [] others

        -- Drop 10 positions so we dont check collisions with ourselves
        myPath =
            drop 10 player.path

    in
        filter isVisible (concat [myPath, otherPaths])


move : Time -> Player -> Player
move delta player =
    let
        position =
            Maybe.withDefault (Visible (0, 0)) (head player.path)

        (x, y) =
            asXY position

        angle =
            case player.direction of
                Left -> player.angle + maxAngleChange
                Right -> player.angle + -maxAngleChange
                Straight -> player.angle

        vx =
            cos (angle * pi / 180)

        vy =
            sin (angle * pi / 180)

        nextX =
            x + vx * (delta * speed)

        nextY =
            y + vy * (delta * speed)

        path' =
            puncture player.path <| randomHole <| truncate nextX

    in
        { player | angle = angle
                 , path = Visible (nextX, nextY) :: path'
        }


puncture path length =
    if length < 1 then
        path

    else
        let
            withMargin =
                take (length+1) path

            margin =
                take 1 withMargin

            toPuncture =
                drop 1 withMargin

            rest =
                drop (length+1) path

            punctured = map (asXY >> Hidden) toPuncture

        in
            concat [margin, punctured, rest]


randomHole : Int -> Int
randomHole seedInt =
    let
        seed =
            Random.initialSeed seedInt

        (n, _) =
            Random.generate (Random.int 0 150) seed

    in
        -- One chance out of 150 for n to be 1
        if n == 1 then
            fst (Random.generate (Random.int 2 5) seed)

        else
            0


randomAngle : Int -> Float
randomAngle seedInt =
    let
        seed =
            Random.initialSeed seedInt

        (n, _) =
            Random.generate (Random.int 0 360) seed

    in
        toFloat n


randomPosition : Int -> (Int, Int) -> (Float, Float)
randomPosition seedInt (w, h) =
    let
        seed =
            Random.initialSeed seedInt

        safetyMargin =
            200

        w' =
            w - safetyMargin

        h' =
            h - safetyMargin

        (x, _) =
            Random.generate (Random.int (w' // 2) -(w' // 2)) seed

        (y, _) =
            Random.generate (Random.int (h' // 2) -(h' // 2)) seed

    in
        (toFloat x, toFloat y)


-- are n and m within c of each other?
near : Float -> Float -> Float -> Bool
near n c m =
    m >= n-c && m <= n+c


hitSnake : Position (Float, Float) -> Position (Float, Float) -> Bool
hitSnake position1 position2 =
    let
        (x1, y1) =
            asXY position1

        (x2, y2) =
            asXY position2

    in
        near x1 snakeWidth x2
        && near y1 snakeWidth y2


hitWall : Position (Float, Float) -> (Int, Int) -> Bool
hitWall position (w, h) =
    let
        (w', h') =
            (toFloat w, toFloat h)

    in
        case position of
            Visible (x, y) ->
                if      x >= (w' / 2)  then True
                else if x <= -(w' / 2) then True
                else if y >= (h' / 2)  then True
                else if y <= -(h' / 2) then True
                else                       False

            Hidden _ ->
                False


mapInputs : List Player -> Set.Set Char.KeyCode -> List Player
mapInputs players keys =
    let directions =
        map (toDirection keys) players

    in
        map2 (\p d -> { p | direction = d }) players directions


toDirection : Set.Set Char.KeyCode -> Player -> Direction
toDirection keys player =
    if Set.member player.leftKey keys
         && Set.member player.rightKey keys then
        Straight

    else if Set.member player.leftKey keys then
        Left

    else if Set.member player.rightKey keys then
        Right

    else
        Straight


playerSelect : Set.Set Char.KeyCode -> Maybe Int
playerSelect keys =
    if Set.member 49 keys then
        Just 1

    else if Set.member 50 keys then
        Just 2

    else if Set.member 51 keys then
        Just 3

    else
        Nothing


space : Set.Set Char.KeyCode -> Bool
space keys =
    Set.member 32 keys

