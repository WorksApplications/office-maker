module BugReport exposing (..) -- where

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


{-



module BugReport exposing (..) -- where

import Html exposing (div, hr, text)
import Html.App exposing (beginnerProgram)
import Html.Attributes exposing (name, style)
import Html.Events exposing (onMouseDown, onMouseUp, onClick, onDoubleClick, onWithOptions)
import Json.Decode as Json


main =
  beginnerProgram { model = "init", view = view, update = update }

-- onWithOptions "click" { preventDefault = True, stopPropagation = True } (Json.succeed Click)

view model =
  div []
    ((if model == "down" then [ div [] [text ""] ] else []) ++
    [ div
      [ onMouseDown MouseDown
      -- , onMouseUp MouseUp
      , onClick Click
      ] [ text "click me" ]
    , div [] [ text model ]
    ])


type Msg = MouseDown | MouseUp | Click

update msg model =
  case Debug.log "msg" msg of
    MouseDown ->
      "down"
    MouseUp ->
      "up"
    Click ->
      "clicked"


-}
