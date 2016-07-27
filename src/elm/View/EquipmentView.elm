module View.EquipmentView exposing (noEvents, viewDesk, viewLabel)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode
import Util.HtmlUtil exposing (..)
import View.Styles as S
import View.Icons as Icons
import Model.Scale as Scale
import String

type alias Id = String


type alias EventOptions msg =
  { onMouseDown : Maybe msg
  , onMouseUp : Maybe msg
  , onStartEditingName : Maybe msg
  , onContextMenu : Maybe msg
  , onStartResize : Maybe msg
  }


noEvents : EventOptions msg
noEvents =
  { onMouseDown = Nothing
  , onMouseUp = Nothing
  , onStartEditingName = Nothing
  , onContextMenu = Nothing
  , onStartResize = Nothing
  }


viewDesk : EventOptions msg -> Bool -> (Int, Int, Int, Int) -> String -> String -> Bool -> Bool -> Scale.Model -> Bool -> Bool -> Html msg
viewDesk eventOptions showPersonMatch rect color name selected alpha scale disableTransition personMatched =
  let
    personMatchIcon =
      if showPersonMatch then
        personMatchingView name personMatched
      else
        text ""

    screenRect =
      Scale.imageToScreenForRect scale rect

    styles =
      [ style (S.deskObject screenRect color selected alpha disableTransition) ]

    nameView =
      equipmentLabelView "" 12 scale disableTransition screenRect name
  in
    viewInternal eventOptions styles nameView personMatchIcon


viewLabel : EventOptions msg -> (Int, Int, Int, Int) -> String -> String -> Float -> Bool -> Bool -> Scale.Model -> Bool -> Html msg
viewLabel eventOptions rect fontColor name fontSize selected rectVisible scale disableTransition =
  let
    screenRect =
      Scale.imageToScreenForRect scale rect

    styles =
      [ style (S.labelObject screenRect fontColor selected rectVisible disableTransition) ]

    nameView =
      equipmentLabelView fontColor fontSize scale disableTransition screenRect name
  in
    viewInternal eventOptions styles nameView (text "")


viewInternal : EventOptions msg -> List (Html.Attribute msg) -> Html msg -> Html msg -> Html msg
viewInternal eventOptions styles nameView personMatchIcon =
  let
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
      ) ++
      ( case eventOptions.onStartResize of
          Just msg -> [ onDoubleClick msg ]
          Nothing -> []
      )
  in
    div
      ( styles ++ eventHandlers )
      [ nameView
      , personMatchIcon
      , resizeGripView eventOptions.onStartResize
      ]


resizeGripView : Maybe msg -> Html msg
resizeGripView onStartResize =
  case onStartResize of
    Just msg ->
      div
        [ style S.deskResizeGrip
        , onWithOptions "mousedown" { stopPropagation = True, preventDefault = False } (Decode.succeed msg)
        ]
        []
    Nothing ->
      text ""


personMatchingView : String -> Bool -> Html msg
personMatchingView name personMatched =
  if name /= "" && personMatched then
    div [ style S.personMatched ] [ Icons.personMatched ]
  else if name /= "" && not personMatched then
    div [ style S.personNotMatched ] [ Icons.personNotMatched ]
  else
    text ""


equipmentLabelView : String -> Float -> Scale.Model -> Bool -> (Int, Int, Int, Int) -> String -> Html msg
equipmentLabelView color fontSize scale disableTransition screenRect name =
  let
    (_, _, _, height) =
      screenRect

    trimed =
      String.trim name

    ratio =
      Scale.imageToScreenRatio scale

    styles =
      S.nameLabel
        color
        height
        (List.length (String.lines trimed))
        (ratio * fontSize)
        disableTransition  --TODO
  in
    pre
      [ style styles ]
      [ text trimed ]
