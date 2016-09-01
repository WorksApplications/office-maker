module View.PropertyView exposing (view)

import Maybe

import Html exposing (..)
import Html.Attributes exposing (..)

import View.Styles as S
import View.Icons as Icons

import Util.HtmlUtil exposing (..)

import Model exposing (..)
import Model.Object as Object
import Model.ObjectsOperation as ObjectsOperation exposing (..)


view : Model -> List (Html Msg)
view model =
  let
    selectedObjects = Model.selectedObjects model
  in
    if selectedObjects == [] then
      []
    else
      [ if List.all Object.backgroundColorEditable selectedObjects then
          row [ label Icons.backgroundColorPropLabel, backgroundColorView model ]
        else
          text ""
      , if List.all Object.colorEditable selectedObjects then
          row [ label Icons.colorPropLabel, colorView model ]
        else
          text ""
      , if List.all Object.shapeEditable selectedObjects then
          row [ label Icons.shapePropLabel, shapeView model ]
        else
          text ""
      ] -- TODO fontSize, name, icon?


label : Html Msg -> Html Msg
label icon =
  div [] [ icon ]


row : List (Html msg) -> Html msg
row children =
  div [ style S.formControl ] children


backgroundColorView : Model -> Html Msg
backgroundColorView model =
  paletteView
    SelectBackgroundColor
    (backgroundColorProperty (selectedObjects model))
    model.colorPalette.backgroundColors


colorView : Model -> Html Msg
colorView model =
  paletteView
    SelectColor
    (colorProperty (selectedObjects model))
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
      shapeProperty (selectedObjects model)

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
