module Page.Map.LinkCopy exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import View.CommonStyles as CS


-- copy : Msg -> Cmd msg
-- copy (Copy inputId) =
--   copyLink inputId


inputId : String
inputId =
    "copy-link-input"


view : String -> Html msg
view url =
    div [ style styles ]
        [ input [ id inputId, style CS.input, value url ] []
        , button
            [ style CS.button

            -- , onClick (toMsg (Copy inputId))
            ]
            [ text "Copy" ]
        ]


styles : List ( String, String )
styles =
    []
