module Page.Map.PrintGuide exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Lazy as Lazy exposing (..)
import Model.I18n as I18n exposing (Language)
import View.Styles as Styles
import Util.StyleUtil exposing (..)
import Page.Map.Msg exposing (Msg(..))


view : Language -> Bool -> Html Msg
view lang isPrintMode =
    if isPrintMode then
        div
            [ style containerStyle
            , class "no-print"
            ]
            [ div [ style (itemStyle 2245 1587) ] [ text "A2" ]
            , div [ style (itemStyle 1587 1122) ] [ text "A3" ]
            , div [ style (itemStyle 1122 793) ] [ text "A4", lazy button lang ]
            ]
    else
        text ""


button : Language -> Html Msg
button lang =
    div
        [ style buttonStyle
        , onClick Print
        ]
        [ text (I18n.print lang) ]


color : String
color =
    "rgb(200, 150, 220)"


containerStyle : List ( String, String )
containerStyle =
    [ ( "position", "fixed" )
    , ( "z-index", Styles.zPrintGuide )
    , ( "top", "0" )
    , ( "left", "0" )
    , ( "pointer-events", "none" )
    ]


itemStyle : Int -> Int -> List ( String, String )
itemStyle width height =
    [ ( "position", "fixed" )
    , ( "top", "0" )
    , ( "left", "0" )
    , ( "width", px width )
    , ( "height", px height )
    , ( "border", "dashed 5px " ++ color )
    , ( "font-size", "x-large" )
    , ( "font-weight", "bold" )
    , ( "color", color )
    , ( "text-align", "right" )
    , ( "padding-right", "3px" )
    ]


buttonStyle : List ( String, String )
buttonStyle =
    [ ( "border", "2px solid " ++ color )
    , ( "color", "white" )
    , ( "margin", "auto" )
    , ( "position", "absolute" )
    , ( "top", "0" )
    , ( "bottom", "0" )
    , ( "left", "0" )
    , ( "right", "0" )
    , ( "width", "300px" )
    , ( "height", "150px" )
    , ( "line-height", "150px" )
    , ( "text-align", "center" )
    , ( "font-size", "3em" )
    , ( "font-weight", "normal" )
    , ( "cursor", "pointer" )
    , ( "background-color", color )
    , ( "opacity", "0.4" )
    , ( "pointer-events", "all" )
    ]
