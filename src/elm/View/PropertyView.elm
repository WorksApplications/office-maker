module View.PropertyView exposing (view)

import Maybe

import Html exposing (..)
import Html.Attributes exposing (..)

import View.Styles as S
import View.Icons as Icons

import Util.HtmlUtil exposing (..)

import Model exposing (..)
import Model.Equipment as Equipment
import Model.EquipmentsOperation as EquipmentsOperation exposing (..)


view : Model -> List (Html Msg)
view model =
  [ if List.all Equipment.backgroundColorEditable (selectedEquipments model) then
      row [ label Icons.backgroundColorPropLabel, backgroundColorView model ]
    else text ""
  , if List.all Equipment.colorEditable (selectedEquipments model) then
      row [ label Icons.colorPropLabel, colorView model ]
    else text ""
  , if List.all Equipment.shapeEditable (selectedEquipments model) then
      row [ label Icons.shapePropLabel, shapeView model ]
    else text ""
  ]


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
    (backgroundColorProperty (selectedEquipments model))
    model.colorPalette


colorView : Model -> Html Msg
colorView model =
  paletteView
    SelectColor
    (colorProperty (selectedEquipments model))
    model.colorPalette


paletteView : (String -> Msg) -> Maybe String -> List String -> Html Msg
paletteView toMsg selectedColor colorPalette =
  let
    match color =
      case selectedColor of
        Just c -> color == c
        Nothing -> False
  in
    ul
      [ style S.colorProperties ]
      (List.map (paletteViewEach toMsg match) colorPalette)


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
      shapeProperty (selectedEquipments model)

    shapes =
      [ Equipment.Rectangle, Equipment.Ellipse ]

    match shape =
      case selectedShape of
        Just s -> shape == s
        Nothing -> False

    toIcon shape =
      case shape of
        Equipment.Rectangle -> Icons.shapeRectangle
        Equipment.Ellipse -> Icons.shapeEllipse
  in
    ul
      [ style S.shapeProperties ]
      (List.map (shapeViewEach SelectShape match toIcon) shapes)


shapeViewEach : (Equipment.Shape -> Msg) -> (Equipment.Shape -> Bool) -> (Equipment.Shape -> Html Msg) -> Equipment.Shape -> Html Msg
shapeViewEach toMsg match toIcon shape =
  li
    [ style (S.shapeProperty (match shape))
    , onMouseDown' (toMsg shape)
    ]
    [ toIcon shape ]
