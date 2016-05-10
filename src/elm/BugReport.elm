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
