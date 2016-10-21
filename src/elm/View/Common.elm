module View.Common exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)

import View.CommonStyles as S


card : List (Html msg) -> Html msg
card children =
  div [ style S.card ] children


formControl : List (Html msg) -> Html msg
formControl children =
  div [ style S.formControl ] children
