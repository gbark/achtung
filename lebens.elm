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
import Random


type State = Play | Pause


type alias Game =
    { players: List Player
    , state: State
    , viewport: (Int, Int)
    }


type alias Player =
    { id: Int
    , path: List (Point (Float, Float))
    , angle: Float
    , direction: Direction
    , alive: Bool
    , score: Int
    , color: Color
    , leftKey: Char.KeyCode
    , rightKey: Char.KeyCode
    , hole: Int
    }


type alias Input =
    { space: Bool
    , keys: Set.Set Char.KeyCode
    , delta: Time
    , viewport: (Int, Int)
    , time: Time
    }


type Direction
    = Left
    | Right
    | Straight


type Point a = Visible a | Hidden a


maxAngleChange = 5
speed = 100


defaultPlayer : Player
defaultPlayer =
    { id = 1
    , path = []
    , angle = 0
    , direction = Straight
    , alive = True
    , score = 0
    , color = rgb 74 167 43
    , leftKey = (Char.toCode 'A')
    , rightKey = (Char.toCode 'S')
    , hole = 0
    }


player2 : Player
player2 =
    { defaultPlayer | id = 2
                    , color = rgb 60 100 60
                    , leftKey = 37
                    , rightKey = 39
    }


defaultGame : Game
defaultGame =
    { players = [defaultPlayer, player2]
    , state = Pause
    , viewport = (0, 0)
    }


update : Input -> Game -> Game
update {space, keys, delta, viewport, time} ({players, state} as game) =
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
                map (updatePlayer delta viewport time players)
                    (mapInputs players keys)

    in
        { game | players = newPlayers
               , viewport = viewport
               , state = newState
        }


initPlayer : Player -> (Int, Int) -> Time -> Player
initPlayer player viewport time =
    let
        seed = (truncate (inMilliseconds time)) + player.id

    in
        { player | angle = randomAngle seed
                 , path = [Visible (randomPoint seed viewport)]
        }


updatePlayer : Time -> (Int, Int) -> Time -> List Player -> Player -> Player
updatePlayer delta viewport time allPlayers player =
    if not player.alive then
        player

    else if length player.path < 1 then
        initPlayer player viewport time

    else
        let
            movedPlayer = move delta player
            newPos = Maybe.withDefault (Visible (0, 0)) (head movedPlayer.path)
            paths = foldl (\p acc -> append p.path acc) [] allPlayers
            visibles = filter (\p -> isVisible p) paths
            hs = any (hitSnake newPos) visibles
            hw = hitWall newPos viewport

        in
            if hs || hw then
                { player | alive = False }

            else
                movedPlayer


move : Time -> Player -> Player
move delta player =
    let
        point = Maybe.withDefault (Visible (0, 0)) (head player.path)
        (x, y) =
            case point of
                Visible p ->
                    p

                Hidden p ->
                    p

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

        visibility =
            if player.hole > 0 then Hidden else Visible

        nextHole =
            if player.hole < 0 then
                randomHole (truncate nextX)
            else
                player.hole - 1

    in
        { player | angle = nextAngle
                 , path = visibility (nextX, nextY) :: player.path
                 , hole = nextHole
        }


randomHole : Int -> Int
randomHole seedInt =
    let
        seed =
            Random.initialSeed seedInt

        (n, _) =
            Random.generate (Random.int 0 150) seed

    in
        if n == 1 then
            let
                (length, _) =
                    Random.generate (Random.int 5 25) seed

            in
                length

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


randomPoint : Int -> (Int, Int) -> (Float, Float)
randomPoint seedInt (w, h) =
    let
        seed =
            Random.initialSeed seedInt

        (x, _) =
            Random.generate (Random.int (w // 2) -(w // 2)) seed

        (y, _) =
            Random.generate (Random.int (h // 2) -(h // 2)) seed

    in
        (toFloat x, toFloat y)


-- are n and m within c of each other?
near : Float -> Float -> Float -> Bool
near n c m =
    m >= n-c && m <= n+c


hitSnake : Point (Float, Float) -> Point (Float, Float) -> Bool
hitSnake point1 point2 =
    let
        (x1, y1) =
            asXY point1

        (x2, y2) =
            asXY point2

    in
        near x1 1.9 x2
        && near y1 1.9 y2


hitWall : Point (Float, Float) -> (Int, Int) -> Bool
hitWall point (w', h') =
    let (w, h) = (toFloat w', toFloat h')

    in
        case point of
            Visible (x, y) ->
                if      x >= (w / 2)  then True
                else if x <= -(w / 2) then True
                else if y >= (h / 2)  then True
                else if y <= -(h / 2) then True
                else                       False

            Hidden _ ->
                False


view : Game -> Element
view game =
    let
        (w', h') =
            game.viewport

        (w, h) =
            (toFloat w', toFloat h')

        lines =
            (map renderPlayer game.players)

    in
        collage w' h'
            (append
                [ rect w h
                    |> filled (rgb 000 000 000)
                ] (concat lines)
            )


renderPlayer : Player -> List Form
renderPlayer player =
    let
        coords =
            foldr toGroups [] player.path

        lineStyle =
            solid player.color

        visibleCoords =
            filter isGroupOfVisibles coords

        points =
            map (\pts -> map asXY pts) visibleCoords

    in
        map (\pts -> traced lineStyle (path pts)) points


asXY : Point (Float, Float) -> (Float, Float)
asXY point =
    case point of
        Visible (x, y) -> (x, y)
        Hidden (x, y) -> (x, y)


isGroupOfVisibles : List (Point (Float, Float)) -> Bool
isGroupOfVisibles points =
    case points of
        [] ->
            False

        p :: _ ->
            isVisible p


isVisible : Point (Float, Float) -> Bool
isVisible point =
    case point of
        Visible _ ->
            True

        Hidden _ ->
            False


-- foldr toGroups [] [Visible (0,1), Visible (0,2), Hidden (0,3), Hidden (0,4), Visible (0,5)]
-- ->
-- [[Visible (0,1), Visible (0,2)], [Hidden (0,3) ,Hidden (0,4)], [Visible (0,5)]]
--
-- TODO: Make this less of a mind f@%*
toGroups : Point (Float, Float) -> List (List (Point (Float, Float))) -> List (List (Point (Float, Float)))
toGroups point acc =
    case acc of
        [] ->
            [point] :: acc

        x :: xs ->
            case x of
                [] ->
                    [point] :: acc

                y :: ys ->
                    case y of
                        Visible _ ->
                            case point of
                                Visible _ ->
                                    (point :: x) :: xs

                                Hidden _ ->
                                    [point] :: acc

                        Hidden _ ->
                            case point of
                                Visible _ ->
                                    [point] :: acc

                                Hidden _ ->
                                    (point :: x) :: xs


mapInputs : List Player -> Set.Set Char.KeyCode -> List Player
mapInputs players keys =
    let directions =
        map (toDirection keys) players

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
        Signal.map5 Input
            Keyboard.space
            Keyboard.keysDown
            delta
            Window.dimensions
            (every millisecond)