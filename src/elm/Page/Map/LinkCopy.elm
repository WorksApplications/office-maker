port module Page.Map.LinkCopy exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

import View.CommonStyles as CS


port copyLink : String -> Cmd msg


copy : Msg -> Cmd msg
copy (Copy inputId) =
  copyLink inputId


type Msg =
  Copy String


inputId : String
inputId =
  "copy-link-input"


view : (Msg -> msg) -> String -> Html msg
view toMsg text =
  div [ style styles ]
    [ input [ id inputId, style CS.input, value text ] []
    , button [ onClick (toMsg (Copy inputId))] [ style CS.button ]
    ]


styles : List (String, String)
styles =
  []
