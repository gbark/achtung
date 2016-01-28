import Color exposing (..)
import Window
import Graphics.Collage exposing (..)
import Graphics.Element exposing (..)
import Keyboard
import Debug
import Char
import Time exposing (..)
import List exposing (..)
import Set


type State = Play | Pause


type alias Game =
    { players: List Player
    , state: State
    , viewport: (Int, Int)
    }


type alias Player =
    { id: Int
    , path: List (Float, Float)
    , angle: Float
    , direction: Direction
    , alive: Bool
    , score: Int
    , color: Color
    , leftKey: Char.KeyCode
    , rightKey: Char.KeyCode
    }


type alias Input =
    { space: Bool
    , keys: Set.Set Char.KeyCode
    , delta: Time
    , viewport: (Int, Int)
    }


type Direction
    = Left
    | Right
    | Straight


maxAngleChange = 5
speed = 100


defaultPlayer : Player
defaultPlayer =
    { id = 1
    , path = [(0, 0)] -- randomize
    , angle = 90 -- randomize
    , direction = Straight
    , alive = True
    , score = 0
    , color = rgb 74 167 43
    , leftKey = (Char.toCode 'A')
    , rightKey = (Char.toCode 'S')
    }


player2 : Player
player2 =
    { defaultPlayer | id = 2
                    , path = [(30, -30)]
                    , angle = 95
                    , color = rgb 60 100 60
                    , leftKey = (Char.toCode 'K')
                    , rightKey = (Char.toCode 'L')
    }


defaultGame : Game
defaultGame =
    { players = [defaultPlayer, player2]
    , state = Pause
    , viewport = (0, 0)
    }


update : Input -> Game -> Game
update {space, keys, delta, viewport} ({players, state} as game) =
    let
        newState =
            if space then
                Play

            else if (length (filter (\p -> p.alive) players) < 2) then
                Pause

            else
                state

        newPlayers =
            if state == Pause then
                players

            else
                map (updatePlayer delta viewport players) (mapInputs players keys)

    in
        { game | players = newPlayers
               , viewport = viewport
               , state = newState
        }


updatePlayer : Time -> (Int, Int) -> List Player -> Player -> Player
updatePlayer delta viewport allPlayers player =
    if not player.alive then
        player

    else
        let
            movedPlayer = move delta player
            newPos = Maybe.withDefault (0, 0) (head movedPlayer.path)
            paths = foldl (\p acc -> append p.path acc) [] allPlayers
            hs = any (hitSnake newPos) paths
            hw = hitWall newPos viewport

        in
            if hs || hw then
                { player | alive = False }

            else
                movedPlayer


move : Time -> Player -> Player
move delta player =
    let
        (x, y) =
            Maybe.withDefault (0, 0) (head player.path)

        nextAngle =
            case player.direction of
                Left ->
                    player.angle + maxAngleChange

                Right ->
                    player.angle + -maxAngleChange

                Straight ->
                    player.angle

        vx = cos (nextAngle * pi / 180)
        vy = sin (nextAngle * pi / 180)
        nextX = x + vx * (delta * speed)
        nextY = y + vy * (delta * speed)

    in
        { player | angle = nextAngle
                 , path = (nextX, nextY) :: player.path
        }


-- are n and m within c of each other?
near : Float -> Float -> Float -> Bool
near n c m =
    m >= n-c && m <= n+c


hitSnake : (Float, Float) -> (Float, Float) -> Bool
hitSnake (x1, y1) (x2, y2) =
    near x1 1.9 x2
    && near y1 1.9 y2


hitWall : (Float, Float) -> (Int, Int) -> Bool
hitWall (x, y) (w', h') =
    let (w, h) = (toFloat w', toFloat h')
    in
        if      x >= (w / 2)  then True
        else if x <= -(w / 2) then True
        else if y >= (h / 2)  then True
        else if y <= -(h / 2) then True
        else                       False


view : Game -> Element
view game =
    let
        (w', h') = game.viewport
        (w, h) = (toFloat w', toFloat h')

    in
        collage w' h'
            (append
                [ rect w h
                    |> filled (rgb 000 000 000)
                ] (map renderPlayer game.players)
            )


renderPlayer : Player -> Form
renderPlayer player =
    traced (solid player.color) (path player.path)


mapInputs : List Player -> Set.Set Char.KeyCode -> List Player
mapInputs players keys =
    let directions = map (toDirection keys) players
    in  map2 (\p d -> {p | direction = d}) players directions


toDirection : Set.Set Char.KeyCode -> Player -> Direction
toDirection keys player =
    if Set.isEmpty keys then
        Straight

    else if Set.member player.leftKey keys
         && Set.member player.rightKey keys then
        Straight

    else if Set.member player.leftKey keys then
        Left

    else if Set.member player.rightKey keys then
        Right

    else
        Straight


main : Signal Element
main =
    Signal.map view gameState


gameState : Signal Game
gameState =
    Signal.foldp update defaultGame (input defaultGame)


delta : Signal Time
delta =
    Signal.map inSeconds (fps 35)


input : Game -> Signal Input
input game =
    Signal.sampleOn delta <|
        Signal.map4 Input
            Keyboard.space
            Keyboard.keysDown
            delta
            Window.dimensions