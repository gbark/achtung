import Color exposing (..)
import Window
import Graphics.Collage exposing (..)
import Graphics.Element exposing (..)
import Keyboard
import Debug
import Char
import Time exposing (..)
import Set


type alias Model =
    { path : List (Float, Float)
    , vx: Float
    , vy: Float
    , angle: Float
    }


type Direction = Left | Right | Straight


maxAngleChange = 5
speed = 100


snake : Model
snake =
    { path = [(0, 0)]
    , vx = 0
    , vy = 0
    , angle = 90
    }


update : (Time, Direction) -> Model -> Model
update (dt, dir) snake =
    let
        newSnake = physicsUpdate dt (stepV snake dir)
        head = Maybe.withDefault (0, 0) (List.head newSnake.path)
        tail = Maybe.withDefault [(1, 1)] (List.tail snake.path)
    in
        if List.any (colliding head) tail then
            snake
        else
            newSnake


physicsUpdate : Time -> Model -> Model
physicsUpdate dt snake =
    let
        (x, y) = Maybe.withDefault (0, 0) (List.head snake.path)
        nextX = x + snake.vx * (dt*speed)
        nextY = y + snake.vy * (dt*speed)
        newSnake = { snake |
            path = (nextX, nextY) :: snake.path
        }
    in
        newSnake


stepV : Model -> Direction -> Model
stepV snake dir =
    let angle =
        case dir of
            Left ->
                snake.angle + maxAngleChange
            Right ->
                snake.angle + -maxAngleChange
            Straight ->
                snake.angle
    in
        { snake |
            vx = cos (angle * pi / 180),
            vy = sin (angle * pi / 180),
            angle = angle
        }


-- are n and m near each other?
-- specifically are they within c of each other?
near : Float -> Float -> Float -> Bool
near n c m =
    m >= n-c && m <= n+c


-- is the snake within its tail?
colliding : (Float, Float) -> (Float, Float) -> Bool
colliding (x1, y1) (x2, y2) =
    near x1 2 x2
    && near y1 2 y2


view : (Int, Int) -> Model -> Element
view (w', h') snake =
    let
        (w, h) = (toFloat w', toFloat h')

    in
        collage w' h'
            [ rect w h
                |> filled (rgb 000 000 000)
            , traced (solid (rgb 74 167 43)) (path snake.path)
            ]


main : Signal Element
main =
    Signal.map2 view Window.dimensions (Signal.foldp update snake input)


input : Signal (Time, Direction)
input =
    let
        delta = Signal.map inSeconds (fps 35)
        dir = Signal.map toDirection Keyboard.keysDown
    in
        Signal.sampleOn delta (Signal.map2 (,) delta dir)


toDirection : Set.Set Char.KeyCode -> Direction
toDirection keys =
    if Set.isEmpty keys then
        Straight
    else if Set.size keys > 1 then
        Straight
    else if Set.member (Char.toCode 'A') keys then
        Left
    else if Set.member (Char.toCode 'S') keys then
        Right
    else
        Straight
