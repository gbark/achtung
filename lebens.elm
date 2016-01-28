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
    , viewportSize: (Int, Int)
    }


type alias Player =
    { path: List (Float, Float)
    , vx: Float
    , vy: Float
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
    --, directions: List Direction
    , keys: Set.Set Char.KeyCode
    , delta: Time
    , viewportSize: (Int, Int)
    }


type Direction
    = Left
    | Right
    | Straight


maxAngleChange = 5
speed = 100


defaultPlayer : Player
defaultPlayer =
    { path = [(0, 0)] -- randomize
    , vx = 0
    , vy = 0
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
    { defaultPlayer | path = [(30, -30)]
                    , angle = 95
                    , color = rgb 60 100 60
                    , leftKey = (Char.toCode 'K')
                    , rightKey = (Char.toCode 'L')
    }


defaultGame : Game
defaultGame =
    { players = [defaultPlayer, player2]
    , state = Play
    , viewportSize = (0, 0)
    }


update : Input -> Game -> Game
update {space, keys, delta, viewportSize} ({players, state} as game) =
    let playersWithDirection = mapInputs players keys
    in
        { game | players = map (updatePlayer delta) playersWithDirection
               , viewportSize = viewportSize
        }


updatePlayer : Time -> Player -> Player
updatePlayer delta player =
    let
        nextPlayer = stepPlayer delta player
        h = Maybe.withDefault (0, 0) (head nextPlayer.path)
        t = Maybe.withDefault [(1, 1)] (tail player.path)
    in
        if any (colliding h) t then
            player
        else
            nextPlayer


stepPlayer : Time -> Player -> Player
stepPlayer delta player =
    let
        (x, y) = Maybe.withDefault (0, 0) (head player.path)
        nextAngle =
            case player.direction of
                Left ->
                    player.angle + maxAngleChange
                Right ->
                    player.angle + -maxAngleChange
                Straight ->
                    player.angle
        nextVx = cos (nextAngle * pi / 180)
        nextVy = sin (nextAngle * pi / 180)
        nextX = x + nextVx * (delta*speed)
        nextY = y + nextVy * (delta*speed)
    in
        { player | vx = nextVx
                 , vy = nextVy
                 , angle = nextAngle
                 , path = (nextX, nextY) :: player.path
        }


-- are n and m within c of each other?
near : Float -> Float -> Float -> Bool
near n c m =
    m >= n-c && m <= n+c


colliding : (Float, Float) -> (Float, Float) -> Bool
colliding (x1, y1) (x2, y2) =
    near x1 2 x2
    && near y1 2 y2


view : Game -> Element
view game =
    let
        (w', h') = game.viewportSize
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
    in
        map2 (\p d -> {p | direction = d}) players directions


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