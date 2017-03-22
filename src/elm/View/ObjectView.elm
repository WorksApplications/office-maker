module View.ObjectView exposing (noEvents, viewDesk, viewLabel)

import Json.Decode as Decode
import Html exposing (..)
import Html.Attributes as Attributes exposing (..)
import Html.Events exposing (..)
import Html.Lazy as Lazy
import Mouse

import View.Styles as S
import View.Icons as Icons
import Model.Scale as Scale exposing (Scale)
import Page.Map.Emoji as Emoji

import CoreType exposing (..)


type alias Id = String


type alias EventOptions msg =
  { onMouseDown : Maybe (Position -> msg)
  , onMouseUp : Maybe (Position -> msg)
  , onClick : Maybe msg
  , onStartEditingName : Maybe msg
  , onContextMenu : Maybe (Attribute msg)
  , onStartResize : Maybe (Position -> msg)
  }


noEvents : EventOptions msg
noEvents =
  { onMouseDown = Nothing
  , onMouseUp = Nothing
  , onClick = Nothing
  , onStartEditingName = Nothing
  , onContextMenu = Nothing
  , onStartResize = Nothing
  }


viewDesk : EventOptions msg -> Bool -> Position -> Size -> String -> String -> Float -> Bool -> Bool -> Scale -> Bool -> Html msg
viewDesk eventOptions showPersonMatch pos size color name fontSize selected alpha scale personMatched =
  let
    personMatchIcon =
      if showPersonMatch then
        Lazy.lazy3 personMatchingView scale name personMatched
      else
        text ""

    screenPos =
      Scale.imageToScreenForPosition scale pos

    screenSize =
      Scale.imageToScreenForSize scale size

    styles =
      [ style (S.deskObject screenPos screenSize color selected alpha) ]

    nameView =
      objectLabelView False "" fontSize scale screenPos screenSize name
  in
    viewInternal selected eventOptions styles nameView personMatchIcon


viewLabel : EventOptions msg -> Position -> Size -> String -> String -> String -> Float -> Bool -> Bool -> Bool -> Bool -> Scale -> Html msg
viewLabel eventOptions pos size backgroundColor fontColor name fontSize isEllipse selected isGhost rectVisible scale =
  let
    screenPos =
      Scale.imageToScreenForPosition scale pos

    screenSize =
      Scale.imageToScreenForSize scale size

    styles =
      [ style (S.labelObject isEllipse screenPos screenSize backgroundColor fontColor selected isGhost rectVisible) ]

    nameView =
      objectLabelView True fontColor fontSize scale screenPos screenSize name
  in
    viewInternal selected eventOptions styles nameView (text "")


viewInternal : Bool -> EventOptions msg -> List (Html.Attribute msg) -> Html msg -> Html msg -> Html msg
viewInternal selected eventOptions styles nameView personMatchIcon =
  let
    eventHandlers =
      ( case eventOptions.onContextMenu of
          Just attr ->
            [ attr ]

          Nothing -> []
      ) ++
      ( case eventOptions.onMouseDown of
          Just msg ->
            [ onWithOptions "mousedown" { stopPropagation = True, preventDefault = True } Mouse.position |> Attributes.map msg
            ]

          Nothing -> []
      ) ++
      ( case eventOptions.onMouseUp of
          Just msg ->
            [ onWithOptions "mouseup" { stopPropagation = True, preventDefault = False } Mouse.position |> Attributes.map msg
            ]

          Nothing -> []
      ) ++
      ( case eventOptions.onClick of
          Just msg ->
            [ onWithOptions "click" { stopPropagation = True, preventDefault = False } (Decode.succeed msg)
            ]

          Nothing -> []
      ) ++
      ( case eventOptions.onStartEditingName of
          Just msg -> [ onDoubleClick msg ]
          Nothing -> []
      )
  in
    div
      ( styles ++ eventHandlers )
      [ nameView
      , personMatchIcon
      , Lazy.lazy2 resizeGripView selected eventOptions.onStartResize
      ]


resizeGripView : Bool -> Maybe (Position -> msg) -> Html msg
resizeGripView selected onStartResize =
  case onStartResize of
    Just msg ->
      (Lazy.lazy resizeGripViewHelp selected)
        |> Html.map msg

    Nothing ->
      text ""


resizeGripViewHelp : Bool -> Html Position
resizeGripViewHelp selected =
  div
    [ style (S.deskResizeGrip selected)
    , onWithOptions "mousedown" { stopPropagation = True, preventDefault = False } Mouse.position
    ]
    []


personMatchingView : Scale -> String -> Bool -> Html msg
personMatchingView scale name personMatched =
  let
    ratio =
      Scale.imageToScreenRatio scale
  in
    if name /= "" && personMatched then
      div [ style (S.personMatched ratio) ] [ Lazy.lazy Icons.personMatched ratio ]
    else if name /= "" && not personMatched then
      div [ style (S.personNotMatched ratio) ] [ Lazy.lazy Icons.personNotMatched ratio ]
    else
      text ""


objectLabelView : Bool -> String -> Float -> Scale -> Position -> Size -> String -> Html msg
objectLabelView canBeEmoji color fontSize scale screenPos screenSize name =
  let
    trimed =
      String.trim name

    ratio =
      Scale.imageToScreenRatio scale

    styles =
      S.nameLabel
        color
        ratio
        fontSize
  in
    div
      [ style styles ]
      [ if canBeEmoji then Emoji.view [] trimed else span [] [ text trimed ]]
