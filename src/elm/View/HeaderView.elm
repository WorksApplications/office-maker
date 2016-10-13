module View.HeaderView exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)

import View.Styles as S


view : String -> Maybe String -> Html msg -> Html msg
view title link menu =
  header
    [ style S.header ]
    [ h1
        [ style S.h1 ]
        [ case link of
            Just url ->
              a [ style S.headerLink, href url ] [ text title ]

            Nothing ->
              text title
         ]
    , menu
    ]
