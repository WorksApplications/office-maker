module View.EquipmentView exposing(noEvents, equipmentView')

import Html exposing (..)
import Html.Attributes exposing (..)
import Util.HtmlUtil exposing (..)
import View.Styles as Styles
import View.Icons as Icons
import Model.Scale as Scale
import Model.Person as Person exposing (Person)

type alias Id = String

type alias EventOptions msg =
  { onMouseDown : Maybe msg
  , onStartEditingName : Maybe msg
  , onContextMenu : Maybe msg
  }

noEvents : EventOptions msg
noEvents =
  { onMouseDown = Nothing
  , onStartEditingName = Nothing
  , onContextMenu = Nothing
  }

equipmentView' : EventOptions msg -> Bool -> String -> (Int, Int, Int, Int) -> String -> String -> Bool -> Bool -> Scale.Model -> Bool -> Maybe Person -> Bool -> Html msg
equipmentView' eventOptions showPersonMatch key' rect color name selected alpha scale disableTransition personInfo personMatched =
  let
    screenRect =
      Scale.imageToScreenForRect scale rect
    styles =
      Styles.desk screenRect color selected alpha disableTransition
    eventHandlers =
      ( case eventOptions.onContextMenu of
          Just msg -> [ onContextMenu' msg ]
          Nothing -> []
      ) ++
      ( case eventOptions.onMouseDown of
          Just msg -> [ onMouseDown' msg ]
          Nothing -> []
      ) ++
      ( case eventOptions.onStartEditingName of
          Just msg -> [ onDblClick' msg ]
          Nothing -> []
      )
  in
    div
      ( eventHandlers ++ [ {- key key', -} style styles ] )
      [ equipmentLabelView scale disableTransition name
      , if showPersonMatch then
          personMatchingView name personMatched
        else
          text ""
      ]

personMatchingView : String -> Bool -> Html msg
personMatchingView name personMatched =
  if name /= "" && personMatched then
    div [ style Styles.personMatched ] [ Icons.personMatched ]
  else if name /= "" && not personMatched then
    div [ style Styles.personNotMatched ] [ Icons.personNotMatched ]
  else
    text ""


equipmentLabelView : Scale.Model -> Bool -> String -> Html msg
equipmentLabelView scale disableTransition name =
  let
    styles =
      Styles.nameLabel
        (Scale.imageToScreenRatio scale)
        disableTransition  --TODO
  in
    pre
      [ style styles ]
      [ text name ]
