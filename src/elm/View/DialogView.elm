module View.DialogView exposing (viewWithSize, viewWithMarginParcentage)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import View.CommonStyles as S


viewWithSize : msg -> Int -> Int -> Int -> List (Html msg) -> Html msg
viewWithSize clickBackgroundMsg backgroundZIndex width height children =
    view clickBackgroundMsg backgroundZIndex (S.dialogWithSize (backgroundZIndex + 1) width height) children


viewWithMarginParcentage : msg -> Int -> Int -> Int -> List (Html msg) -> Html msg
viewWithMarginParcentage clickBackgroundMsg backgroundZIndex top left children =
    view clickBackgroundMsg backgroundZIndex (S.dialogWithMarginParcentage (backgroundZIndex + 1) top left) children


view : msg -> Int -> List ( String, String ) -> List (Html msg) -> Html msg
view clickBackgroundMsg backgroundZIndex dialogStyles children =
    div []
        [ div
            [ style (S.modalBackground backgroundZIndex)
            , onClick clickBackgroundMsg
            ]
            []
        , div
            [ style dialogStyles ]
            children
        ]
