module View.HeaderView exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)

import View.Styles as S


view : Bool -> String -> Maybe String -> Html msg -> Html msg
view printMode title link menu =
  header
    [ style (S.header printMode)
    ]
    [ h1
        [ style S.h1 ]
        [ case link of
            Just url ->
              a
                [ style S.headerLink
                , href url
                ]
                [ text title ]

            Nothing ->
              text title
         ]
    , menu
    ]
