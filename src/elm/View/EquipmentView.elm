module View.EquipmentView exposing (noEvents, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode
import Util.HtmlUtil exposing (..)
import View.Styles as S
import View.Icons as Icons
import Model.Scale as Scale
import Model.Person as Person exposing (Person)

type alias Id = String


type alias EventOptions msg =
  { onMouseDown : Maybe msg
  , onMouseUp : Maybe msg
  , onStartEditingName : Maybe msg
  , onContextMenu : Maybe msg
  }


noEvents : EventOptions msg
noEvents =
  { onMouseDown = Nothing
  , onMouseUp = Nothing
  , onStartEditingName = Nothing
  , onContextMenu = Nothing
  }


view : EventOptions msg -> Bool -> Bool -> (Int, Int, Int, Int) -> String -> String -> Bool -> Bool -> Scale.Model -> Bool -> Maybe Person -> Bool -> Html msg
view eventOptions showPersonMatch resizable rect color name selected alpha scale disableTransition personInfo personMatched =
  let
    screenRect =
      Scale.imageToScreenForRect scale rect

    styles =
      [ style (S.desk screenRect color selected alpha disableTransition) ]

    eventHandlers =
      ( case eventOptions.onContextMenu of
          Just msg -> [ onContextMenu' msg ]
          Nothing -> []
      ) ++
      ( case eventOptions.onMouseDown of
          Just msg ->
            [ onWithOptions "mousedown" { stopPropagation = True, preventDefault = False } (Decode.succeed msg)
            ]
          Nothing -> []
      ) ++
      ( case eventOptions.onMouseUp of
          Just msg ->
            [ onWithOptions "mouseup" { stopPropagation = True, preventDefault = False } (Decode.succeed msg)
            ]
          Nothing -> []
      ) ++
      ( case eventOptions.onStartEditingName of
          Just msg -> [ onDoubleClick msg ]
          Nothing -> []
      )

    resizeGrip =
      if resizable then
        div [ style S.deskResizeGrip ] []
      else
        text ""
  in
    div
      ( styles ++ eventHandlers )
      [ equipmentLabelView scale disableTransition name
      , if showPersonMatch then
          personMatchingView name personMatched
        else
          text ""
      , resizeGrip
      ]

personMatchingView : String -> Bool -> Html msg
personMatchingView name personMatched =
  if name /= "" && personMatched then
    div [ style S.personMatched ] [ Icons.personMatched ]
  else if name /= "" && not personMatched then
    div [ style S.personNotMatched ] [ Icons.personNotMatched ]
  else
    text ""


equipmentLabelView : Scale.Model -> Bool -> String -> Html msg
equipmentLabelView scale disableTransition name =
  let
    styles =
      S.nameLabel
        (Scale.imageToScreenRatio scale)
        disableTransition  --TODO
  in
    pre
      [ style styles ]
      [ text name ]
