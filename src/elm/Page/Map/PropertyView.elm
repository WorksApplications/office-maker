module Page.Map.PropertyView exposing (view)

import Maybe

import Html exposing (..)
import Html.Attributes exposing (..)

import View.Styles as S
import View.Icons as Icons
import View.Common exposing (..)

import Util.HtmlUtil exposing (..)
import Model.Object as Object
import Model.ObjectsOperation as ObjectsOperation

import Page.Map.Msg exposing (..)
import Page.Map.Model as Model exposing (Model, ContextMenu(..), DraggingContext(..))

view : Model -> List (Html Msg)
view model =
  let
    selectedObjects = Model.selectedObjects model
  in
    if selectedObjects == [] then
      []
    else
      [ if List.all Object.backgroundColorEditable selectedObjects then
          formControl [ label Icons.backgroundColorPropLabel, backgroundColorView model ]
        else
          text ""
      , if List.all Object.colorEditable selectedObjects then
          formControl [ label Icons.colorPropLabel, colorView model ]
        else
          text ""
      , if List.all Object.shapeEditable selectedObjects then
          formControl [ label Icons.shapePropLabel, shapeView model ]
        else
          text ""
      , if List.all Object.fontSizeEditable selectedObjects then
          formControl [ label Icons.fontSizePropLabel, fontSizeView model ]
        else
          text ""
      ] -- TODO name, icon?


label : Html Msg -> Html Msg
label icon =
  div [ style S.propertyViewPropertyIcon ] [ icon ]


backgroundColorView : Model -> Html Msg
backgroundColorView model =
  paletteView
    SelectBackgroundColor
    (ObjectsOperation.backgroundColorProperty (Model.selectedObjects model))
    model.colorPalette.backgroundColors


colorView : Model -> Html Msg
colorView model =
  paletteView
    SelectColor
    (ObjectsOperation.colorProperty (Model.selectedObjects model))
    model.colorPalette.textColors


paletteView : (String -> Msg) -> Maybe String -> List String -> Html Msg
paletteView toMsg selectedColor colors =
  let
    match color =
      case selectedColor of
        Just c -> color == c
        Nothing -> False
  in
    ul
      [ style S.colorProperties ]
      (List.map (paletteViewEach toMsg match) colors)


paletteViewEach : (String -> Msg) -> (String -> Bool) -> String -> Html Msg
paletteViewEach toMsg match color =
  li
    [ style (S.colorProperty color (match color))
    , onMouseDown' (toMsg color)
    ]
    []


shapeView : Model -> Html Msg
shapeView model =
  let
    selectedShape =
      ObjectsOperation.shapeProperty (Model.selectedObjects model)

    shapes =
      [ Object.Rectangle, Object.Ellipse ]

    match shape =
      case selectedShape of
        Just s -> shape == s
        Nothing -> False

    toIcon shape =
      case shape of
        Object.Rectangle -> Icons.shapeRectangle
        Object.Ellipse -> Icons.shapeEllipse
  in
    ul
      [ style S.shapeProperties ]
      (List.map (shapeViewEach SelectShape match toIcon) shapes)


shapeViewEach : (Object.Shape -> Msg) -> (Object.Shape -> Bool) -> (Object.Shape -> Html Msg) -> Object.Shape -> Html Msg
shapeViewEach toMsg match toIcon shape =
  li
    [ style (S.shapeProperty (match shape))
    , onMouseDown' (toMsg shape)
    ]
    [ toIcon shape ]


fontSizeView : Model -> Html Msg
fontSizeView model =
  fontSizeViewHelp
    SelectFontSize
    (ObjectsOperation.fontSizeProperty (Model.selectedObjects model))
    [10, 12, 16, 20, 40, 80, 120, 160, 200, 300]


fontSizeViewHelp : (Float -> Msg) -> Maybe Float -> List Float -> Html Msg
fontSizeViewHelp toMsg selectedFontSize sizes =
  let
    match fontSize =
      case selectedFontSize of
        Just size -> fontSize == size
        Nothing -> False
  in
    ul
      [ style S.colorProperties ]
      (List.map (fontSizeViewEach toMsg match) sizes)


fontSizeViewEach : (Float -> Msg) -> (Float -> Bool) -> Float -> Html Msg
fontSizeViewEach toMsg match size =
  li
    [ style (S.colorProperty "" (match size))
    , onMouseDown' (toMsg size)
    ]
    [ text (toString size) ]
