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
    , state = Play
    , viewport = (0, 0)
    }


update : Input -> Game -> Game
update {space, keys, delta, viewport} ({players, state} as game) =
    let playersWithDirection = mapInputs players keys
        nextPlayers = map (updatePlayer delta viewport players) playersWithDirection
    in
        { game | players = nextPlayers
               , viewport = viewport
        }


updatePlayer : Time -> (Int, Int) -> List Player -> Player -> Player
updatePlayer delta viewport allPlayers player =
    if not player.alive then
        player
    else
        let
            nextPlayer = stepPlayer delta player
            nextPos = Maybe.withDefault (0, 0) (head nextPlayer.path)
            snakePaths = foldl (\p acc -> append p.path acc) [] allPlayers
            hitSnake = any (snakeCollision nextPos) snakePaths
            hitWall = wallCollision nextPos viewport
        in
            if hitSnake || hitWall then
                { player | alive = False }
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


snakeCollision : (Float, Float) -> (Float, Float) -> Bool
snakeCollision (x1, y1) (x2, y2) =
    near x1 1.9 x2
    && near y1 1.9 y2


wallCollision : (Float, Float) -> (Int, Int) -> Bool
wallCollision (x, y) (w', h') =
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