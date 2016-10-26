module View.Common exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)

import View.CommonStyles as S


card : Maybe Int -> List (Html msg) -> Html msg
card maybeHeight children =
  div [ style (S.card maybeHeight) ] children


formControl : List (Html msg) -> Html msg
formControl children =
  div [ style S.formControl ] children
