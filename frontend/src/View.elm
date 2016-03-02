module View where


import List exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Graphics.Collage exposing (..)
import Color exposing (..)


import Game exposing (..)
import Player exposing (..)
import Utils exposing (..)
import Position exposing (..)
import Config


view : Game -> Html
view game =
    let
        (w, h) =
            game.gamearea

        (w', h') =
            (toFloat w, toFloat h)

        lines =
            map renderPlayer game.players |> concat

    in
        main' [ style [ ("position", "relative") ] ]
              [ lines
                |> append [ rect w' h' |> filled (rgb 000 000 000) ]
                |> collage w h
                |> fromElement
              , sidebar game
              ]


renderPlayer : Player -> List Form
renderPlayer player =
    let
        coords =
            foldr toGroups [] player.path

        lineStyle =
            { defaultLine | width = Config.snakeWidth
                          , color = player.color
                          , cap = Round
            }

        visibleCoords =
            filter isGroupOfVisibles coords

        positions =
            map (map asXY) visibleCoords

    in
        map (path >> traced lineStyle) positions


sidebar game =
    div [ style [ ("position", "absolute")
                , ("right", "0")
                , ("top", "0")
                , ("width", (toString Config.sidebarWidth) ++ "px")
                , ("height", "100%")
                , ("backgroundColor", "black")
                , ("borderLeft", (toString Config.sidebarBorderWidth) ++ "px solid white")
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

                WaitingPlayers ->
                    "Waiting for more players to join the game"
          ))]
        , (if game.state == Select then
                start
            else
                (scoreboard game)
          )
        , info
        ]


scoreboard game =
    div [] [ (if length game.players > 1 then
                h3 [] [(Html.text ("Round: " ++ toString game.round))]
              else
                h3 [] [(Html.text ("Survivor mode :-O"))]
           )
           , ol [ style [ ("textAlign", "left") ] ]
                (game.players
                    |> sortBy .score
                    |> reverse
                    |> map scoreboardPlayer)
           , p  [ style [ ("color", "grey") ] ] [(Html.text "Press <space> to start")]
           ]


scoreboardPlayer {keyDesc, id, score, color} =
    li [ key (toString id), style [ ("color", (colorToString color)) ] ]
       [ Html.text ("Player "
                    ++ (toString id)
                    ++ " ("
                    ++ keyDesc
                    ++ ") -- "
                    ++ (toString score)
                    ++ " points")
       ]


start =
    div [] [ ul [ style [ ("textAlign", "left"), ("color", "grey") ] ]
                [ li [] [ (Html.text "Press <1> for single player") ]
                , li [] [ (Html.text "Press <2> for two players") ]
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


colorToString c =
    let { red, green, blue } = toRgb c
    in
        "rgb(" ++ (toString red)
        ++ "," ++ (toString green)
        ++ "," ++ (toString blue)
        ++ ")"


isGroupOfVisibles : List (Position (Float, Float)) -> Bool
isGroupOfVisibles positions =
    case positions of
        [] -> False
        p :: _ -> isVisible p