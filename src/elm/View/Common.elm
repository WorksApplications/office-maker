module View.Common exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)

import View.Styles as S


card : List (Html msg) -> Html msg
card children =
  div [ style S.card ] children
