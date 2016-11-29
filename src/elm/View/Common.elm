module View.Common exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)

import View.CommonStyles as S


card : Bool -> String -> Maybe Int -> List (Html msg) -> Html msg
card absolute backgroundColor maxHeight children =
  div [ style (S.cardComponent (if absolute then "absolute" else "") backgroundColor maxHeight) ] children


formControl : List (Html msg) -> Html msg
formControl children =
  div [ style S.formControl ] children
