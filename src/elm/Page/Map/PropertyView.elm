module Page.Map.PropertyView exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Lazy as Lazy
import View.Styles as S
import View.CommonStyles as CS
import View.Icons as Icons
import View.Common exposing (..)
import Util.HtmlUtil exposing (..)
import Model.Object as Object exposing (Object)
import Model.ObjectsOperation as ObjectsOperation
import Model.ColorPalette exposing (ColorPalette)
import Page.Map.Msg exposing (..)
import Page.Map.Model as Model exposing (Model, DraggingContext(..))


view : Model -> List (Html Msg)
view model =
    let
        selectedObjects =
            Model.selectedObjects model
    in
        if selectedObjects == [] then
            []
        else
            [ if List.all Object.backgroundColorEditable selectedObjects then
                formControl [ Lazy.lazy label Icons.backgroundColorPropLabel, Lazy.lazy2 backgroundColorView model.colorPalette selectedObjects ]
              else
                text ""
            , if List.all Object.colorEditable selectedObjects then
                formControl [ Lazy.lazy label Icons.colorPropLabel, Lazy.lazy2 colorView model.colorPalette selectedObjects ]
              else
                text ""
            , if List.all Object.shapeEditable selectedObjects then
                formControl [ Lazy.lazy label Icons.shapePropLabel, Lazy.lazy shapeView selectedObjects ]
              else
                text ""
            , if List.all Object.fontSizeEditable selectedObjects then
                formControl [ Lazy.lazy label Icons.fontSizePropLabel, Lazy.lazy fontSizeView selectedObjects ]
              else
                text ""
            , if List.all Object.urlEditable selectedObjects then
                formControl [ label (text "URL"), urlView (List.head selectedObjects) ]
              else
                text ""
            ]



-- TODO name, icon?


label : Html Msg -> Html Msg
label icon =
    div [ style S.propertyViewPropertyIcon ] [ icon ]


backgroundColorView : ColorPalette -> List Object -> Html Msg
backgroundColorView colorPalette selectedObjects =
    Lazy.lazy3
        paletteView
        SelectBackgroundColor
        (ObjectsOperation.backgroundColorProperty selectedObjects)
        colorPalette.backgroundColors


colorView : ColorPalette -> List Object -> Html Msg
colorView colorPalette selectedObjects =
    Lazy.lazy3
        paletteView
        SelectColor
        (ObjectsOperation.colorProperty selectedObjects)
        colorPalette.textColors


paletteView : (String -> Msg) -> Maybe String -> List String -> Html Msg
paletteView toMsg selectedColor colors =
    let
        match color =
            case selectedColor of
                Just c ->
                    color == c

                Nothing ->
                    False
    in
        ul
            [ style S.colorProperties ]
            (List.map (paletteViewEach toMsg match) colors)


paletteViewEach : (String -> Msg) -> (String -> Bool) -> String -> Html Msg
paletteViewEach toMsg match color =
    li
        [ style (S.colorProperty color (match color))
        , onMouseDown_ (toMsg color)
        ]
        []


shapeView : List Object -> Html Msg
shapeView selectedObjects =
    let
        selectedShape =
            ObjectsOperation.shapeProperty selectedObjects

        shapes =
            [ Object.Rectangle, Object.Ellipse ]

        match shape =
            case selectedShape of
                Just s ->
                    shape == s

                Nothing ->
                    False

        toIcon shape =
            case shape of
                Object.Rectangle ->
                    Icons.shapeRectangle

                Object.Ellipse ->
                    Icons.shapeEllipse
    in
        ul
            [ style S.shapeProperties ]
            (List.map (shapeViewEach SelectShape match toIcon) shapes)


shapeViewEach : (Object.Shape -> Msg) -> (Object.Shape -> Bool) -> (Object.Shape -> Html Msg) -> Object.Shape -> Html Msg
shapeViewEach toMsg match toIcon shape =
    li
        [ style (S.shapeProperty (match shape))
        , onMouseDown_ (toMsg shape)
        ]
        [ toIcon shape ]


fontSizeView : List Object -> Html Msg
fontSizeView selectedObjects =
    Lazy.lazy3
        fontSizeViewHelp
        SelectFontSize
        (ObjectsOperation.fontSizeProperty selectedObjects)
        [ 10, 12, 16, 20, 30, 40, 60, 80, 100, 120, 160 ]


fontSizeViewHelp : (Float -> Msg) -> Maybe Float -> List Float -> Html Msg
fontSizeViewHelp toMsg selectedFontSize sizes =
    let
        match fontSize =
            case selectedFontSize of
                Just size ->
                    fontSize == size

                Nothing ->
                    False
    in
        ul
            [ style S.colorProperties ]
            (List.map (fontSizeViewEach toMsg match) sizes)


fontSizeViewEach : (Float -> Msg) -> (Float -> Bool) -> Float -> Html Msg
fontSizeViewEach toMsg match size =
    li
        [ style (S.colorProperty "" (match size))
        , onMouseDown_ (toMsg size)
        ]
        [ text (toString size) ]


urlView : Maybe Object -> Html Msg
urlView selectedObject =
    selectedObject
        |> Maybe.map
            (\object ->
                div
                    [ onInput (InputObjectUrl [ Object.idOf object ]) ]
                    [ input [ style CS.input, value (Object.urlOf object) ] [] ]
            )
        |> Maybe.withDefault (text "")
