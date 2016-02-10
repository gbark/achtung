module Main where

import Color exposing (..)
import Window
import Graphics.Collage exposing (..)
import Graphics.Element exposing (..)
import Keyboard
import Char
import Time exposing (..)
import List exposing (..)
import Set
import Random
import Html exposing (..)
import Html.Attributes exposing (..)


-- MODEL


type State = Select
           | Start
           | Play
           | Roundover


type alias Game =
    { players: List Player
    , state: State
    , gamearea: (Int, Int)
    , round: Int
    }


type alias Player =
    { id: Int
    , path: List (Position (Float, Float))
    , angle: Float
    , direction: Direction
    , alive: Bool
    , score: Int
    , color: Color
    , leftKey: Char.KeyCode
    , rightKey: Char.KeyCode
    , keyDesc: String
    }


type alias Input =
    { space: Bool
    , keys: Set.Set Char.KeyCode
    , delta: Time
    , gamearea: (Int, Int)
    , time: Time
    }


type Direction
    = Left
    | Right
    | Straight


type Position a = Visible a | Hidden a


maxAngleChange = 5
speed = 125
snakeWidth = 3
sidebarWidth = 250
sidebarBorderWidth = 5


player1 : Player
player1 =
    { id = 1
    , path = []
    , angle = 0
    , direction = Straight
    , alive = True
    , score = 0
    , color = rgb 254 221 3
    , leftKey = (Char.toCode 'Z')
    , rightKey = (Char.toCode 'X')
    , keyDesc = "Z,X"
    }


player2 : Player
player2 =
    { player1 | id = 2
              , color = rgb 229 49 39
              , leftKey = 40
              , rightKey = 39
              , keyDesc = "UP,DN"
    }


player3 : Player
player3 =
    { player1 | id = 3
              , color = rgb 25 100 183
              , leftKey = (Char.toCode 'N')
              , rightKey = (Char.toCode 'M')
              , keyDesc = "N,M"
    }


defaultGame : Game
defaultGame =
    { players = []
    , state = Select
    , gamearea = (0, 0)
    , round = 0
    }


-- UPDATE


update : Input -> Game -> Game
update ({space, keys, delta, gamearea, time} as input) ({players, state, round} as game) =
    let
        state' =
            updateState input game

        players' =
            updatePlayers input game state'

        round' =
            if state == Play && state' == Roundover then
                round + 1

            else
                round

    in
        { game | players = players'
               , gamearea = gamearea
               , state = state'
               , round = round'
        }


updateState : Input -> Game -> State
updateState {space, keys} {players, state} =
    case state of
        Select ->
            if (playerSelect keys) /= Nothing then
                Start

            else
                Select

        Start ->
            if space then
                Play

            else
                Start

        Play ->
            if length (filter (\p -> p.alive) players) == 0 then
                Roundover

            else
                Play

        Roundover ->
            if space then
                Play

            else
                Roundover


updatePlayers : Input -> Game -> State -> List Player
updatePlayers {keys, delta, gamearea, time} {players, state} nextState =
    case nextState of
        Select ->
            players

        Start ->
            if state == Select then
                case (playerSelect keys) of
                    Just n ->
                        if n == 2 then
                            [player1, player2]

                        else if n == 3 then
                            [player1, player2, player3]

                        else
                            []

                    Nothing ->
                        players

            else
                players

        Play ->
            if state == Start || state == Roundover then
                map (initPlayer gamearea time) players

            else
                map (updatePlayer delta gamearea time players)
                (mapInputs players keys)

        Roundover ->
            players


initPlayer : (Int, Int) -> Time -> Player-> Player
initPlayer gamearea time player =
    let
        seed = (truncate (inMilliseconds time)) + player.id

    in
        { player | angle = randomAngle seed
                 , path = [Visible (randomPosition seed gamearea)]
                 , alive = True
        }


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
                if length (filter (\p -> p.alive) players) < 2 then
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

            else
                player'


collisionPaths player players =
    let
        others =
            filter (\p -> p.id /= player.id) players

        otherPaths =
            foldl (\p acc -> append p.path acc) [] others

        -- Drop 10 positions so we dont check collisions with ourselves
        myPath =
            drop 10 player.path

    in
        filter (\p -> isVisible p) (concat [myPath, otherPaths])


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
            puncture player.path (randomHole (truncate nextX))

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

            punctured = map (\p -> let (x,y) = asXY p in Hidden (x,y)) toPuncture

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


-- VIEW


view : Game -> Html
view game =
    let
        (w, h) =
            game.gamearea

        (w', h') =
            (toFloat w, toFloat h)

        lines =
            (map renderPlayer game.players)

    in
        main' [ style [ ("position", "relative") ] ]
              [ fromElement (collage w h
                    (append
                        [ rect w' h'
                            |> filled (rgb 000 000 000)
                        ] (concat lines)
                    )
                )
              , sidebar game
              ]


renderPlayer : Player -> List Form
renderPlayer player =
    let
        coords =
            foldr toGroups [] player.path

        lineStyle =
            { defaultLine | width = snakeWidth
                          , color = player.color
                          , cap = Round
            }

        visibleCoords =
            filter isGroupOfVisibles coords

        positions =
            map (\pts -> map asXY pts) visibleCoords

    in
        map (\pts -> traced lineStyle (path pts)) positions


sidebar game =
    div [ style [ ("position", "absolute")
                , ("right", "0")
                , ("top", "0")
                , ("width", (toString sidebarWidth) ++ "px")
                , ("height", "100%")
                , ("backgroundColor", "black")
                , ("borderLeft", (toString sidebarBorderWidth) ++ "px solid white")
                , ("color", "white")
                , ("textAlign", "center")
                , ("fontFamily", "monospace")
                ]
        ]
        [ h1 [] [(Html.text "ACHTUNG, DIE KURVE!")]
        , h2 [] [(Html.text (case game.state of
                Select ->
                     "Select no of players"

                Start ->
                    ""

                Play ->
                    "Game on!"

                Roundover ->
                    "Round finished!"
          ))]
        , (if game.state == Select then
                start
            else
                (scoreboard game)
          )
        , info
        ]


scoreboard game =
    div [] [ h3 [] [(Html.text ("Round: " ++ toString game.round))]
           , ol [ style [ ("textAlign", "left") ] ] (map scoreboardPlayer (sortBy .score game.players |> reverse))
           , p  [ style [ ("color", "grey") ] ] [(Html.text "Press space to start")]
           ]


scoreboardPlayer {keyDesc, id, score, color} =
    li [ key (toString id), style [ ("color", (colorToString color)) ] ]
       [ Html.text ("Player "
                    ++ (toString id)
                    ++ " ("
                    ++ keyDesc
                    ++ ") -- "
                    ++ (toString score)
                    ++ " wins")
       ]


start =
    div [] [ ul [ style [ ("textAlign", "left"), ("color", "grey") ] ]
                [ li [] [ (Html.text "Press <2> for two players") ]
                , li [] [ (Html.text "Press <3> for three players") ]
                ]
           ]


info =
    div [ style [ ("color", "grey")
                , ("position", "absolute")
                , ("bottom", "10px")
                , ("display", "block")
                , ("width", "100%")
                ]
        ]
        [ p []
            [ (Html.text "Made in ")
            , a [ style [ ("color", "cyan") ], href "http://www.elm-lang.org/" ]
                [ (Html.text "Elm") ]
            , br [] []
            , a [ style [ ("color", "cyan") ], href "https://github.com/gbark/achtung" ]
                [ (Html.text "Fork me on Github") ]
            ]
        ]


-- HELPERS


colorToString c =
    let { red, green, blue } = toRgb c
    in
        "rgb(" ++ (toString red)
        ++ "," ++ (toString green)
        ++ "," ++ (toString blue)
        ++ ")"


asXY : Position (Float, Float) -> (Float, Float)
asXY position =
    case position of
        Visible (x, y) -> (x, y)
        Hidden (x, y) -> (x, y)


isGroupOfVisibles : List (Position (Float, Float)) -> Bool
isGroupOfVisibles positions =
    case positions of
        [] -> False
        p :: _ -> isVisible p


isVisible : Position (Float, Float) -> Bool
isVisible position =
    case position of
        Visible _ -> True
        Hidden _ -> False


-- Usage:
--
-- foldr toGroups [] [Visible (0,1), Visible (0,2), Hidden (0,3), Hidden (0,4), Visible (0,5)]
-- ->
-- [[Visible (0,1), Visible (0,2)], [Hidden (0,3) ,Hidden (0,4)], [Visible (0,5)]]
toGroups : Position (Float, Float) -> List (List (Position (Float, Float))) -> List (List (Position (Float, Float)))
toGroups position acc =
    case acc of
        [] ->
            [position] :: acc

        x :: xs ->
            case x of
                [] ->
                    [position] :: acc

                y :: ys ->
                    if isVisible y && isVisible position then
                        (position :: x) :: xs

                    else
                        [position] :: acc


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
    if Set.member 50 keys then
        Just 2

    else if Set.member 51 keys then
        Just 3

    else
        Nothing


-- SIGNALS


main : Signal Html
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
            (Signal.map (\(w, h) -> (w-sidebarWidth-sidebarBorderWidth, h)) Window.dimensions)
            (every millisecond)