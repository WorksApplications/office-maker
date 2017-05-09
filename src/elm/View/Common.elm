module View.Common exposing (card, formControl)

import Html exposing (..)
import Html.Attributes exposing (..)
import View.CommonStyles exposing (..)
import Util.StyleUtil exposing (..)


card : Bool -> String -> Maybe Int -> Maybe Int -> List (Html msg) -> Html msg
card absolute backgroundColor maxHeight maybeWidth children =
    div
        [ style (cardStyles absolute backgroundColor maxHeight maybeWidth) ]
        children


cardStyles : Bool -> String -> Maybe Int -> Maybe Int -> S
cardStyles absolute backgroundColor maybeMaxHeight maybeWidth =
    (case maybeMaxHeight of
        Just maxHeight ->
            [ ( "max-height", px maxHeight )
            , ( "overflow-y", "scroll" )
            , ( "box-sizing", "border-box" )
            ]

        Nothing ->
            []
    )
        ++ [ ( "background-color", backgroundColor )
           , ( "width", maybeWidth |> Maybe.map px |> Maybe.withDefault "" )
           , ( "position"
             , if absolute then
                "absolute"
               else
                ""
             )
           , ( "z-index"
             , if absolute then
                "1"
               else
                ""
             )
           ]
        ++ View.CommonStyles.card


formControl : List (Html msg) -> Html msg
formControl children =
    div [ style View.CommonStyles.formControl ] children
