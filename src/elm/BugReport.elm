module BugReport exposing (..) -- where
{-
import Html exposing (div, text)
import Html.App exposing (beginnerProgram)
import Html.Events exposing (onMouseDown, onClick)

main =
  beginnerProgram { model = "init", view = view, update = update }

view model =
  div []
    ((if model == "changed" then [ text "" ] else []) ++
    [ div
      [ onClick Click
      , onMouseDown Change
      ] [ text "click me" ]
    , div [] [ text model ]
    ])

type Msg = Change | Click

update msg model =
  case Debug.log "msg" msg of
    Change ->
      "changed"
    Click ->
      "clicked"
-}


import Html exposing (div, text, button)
import Html.Attributes exposing (style)
import Html.App exposing (beginnerProgram)
import Html.Events exposing (onMouseDown, onClick)

main =
  beginnerProgram { model = "init", view = view, update = update }

view model =
  let
    children1 =
      if model == "clicked" then
        [ div
            [ style [("padding-left", "100px")] ]
            [ text "this element's padding-left must be 100px" ] ]
      else
        []

    children2 =
      [ div
          [ style [("padding", "20px")]
          , onClick Click
          ]
          [ text "click me" ]
      ]
  in
    div [] (children1 ++ children2)
    -- div [] (children2 ++ children1) -- this is OK

type Msg = Click

update msg model =
  case msg of
    Click ->
      "clicked"
