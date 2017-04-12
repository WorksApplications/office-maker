module View.ObjectViewSvg exposing (EventOptions, noEvents, viewDesk, viewLabel)

import Json.Decode as Decode
import Svg exposing (..)
import Svg.Attributes as Attributes exposing (..)
import Svg.Events exposing (..)
import Svg.Lazy exposing (..)
import Html
import Html.Attributes
import Html.Events
import Mouse

import View.Styles as S
import View.Icons as Icons
import Model.Scale as Scale exposing (Scale)
import Page.Map.Emoji as Emoji
import Util.StyleUtil exposing (px)

import CoreType exposing (..)


type alias EventOptions msg =
  { onMouseDown : Maybe (Attribute msg)
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


viewDesk : EventOptions msg -> Bool -> Position -> Size -> String -> String -> Float -> Bool -> Bool -> Scale -> Bool -> Svg msg
viewDesk eventOptions showPersonMatch pos size color name fontSize selected alpha scale personMatched =
  let
    personMatchIcon =
      if showPersonMatch then
        lazy3 personMatchingView scale name personMatched
      else
        text ""

    rectStyles =
      [ width (px size.width)
      , height (px size.height)
      , fill color
      , stroke (if selected then "blue" else "black")
      , strokeWidth (if selected then "2" else "1")
      ]

    ----style (S.deskObject screenPos screenSize color selected alpha)
    gStyles =
      [ transform ("translate(" ++ toString pos.x ++ "," ++ toString pos.y ++ ")")
      , fillOpacity (if alpha then "0.5" else "1")
      ]

    nameView =
      objectLabelView False "" fontSize scale pos size name
  in
    viewInternal eventOptions selected gStyles rectStyles nameView personMatchIcon


viewLabel : EventOptions msg -> Position -> Size -> String -> String -> String -> Float -> Bool -> Bool -> Bool -> Bool -> Scale -> Svg msg
viewLabel eventOptions pos size backgroundColor fontColor name fontSize isEllipse selected isGhost rectVisible scale =
  let
    --style (S.labelObject isEllipse screenPos screenSize backgroundColor fontColor selected isGhost rectVisible)

    rectStyles =
      [ width (px size.width)
      , height (px size.height)
      , fill backgroundColor
      , stroke "black"
      ]

    gStyles =
      [ transform ("translate(" ++ toString pos.x ++ "," ++ toString pos.y ++ ")")
      , fillOpacity (if isGhost then "0.5" else "1")
      ]

    nameView =
      objectLabelView True fontColor fontSize scale pos size name
  in
    viewInternal eventOptions selected gStyles rectStyles nameView (text "")


viewInternal : EventOptions msg -> Bool -> List (Svg.Attribute msg) -> List (Svg.Attribute msg) -> Svg msg -> Svg msg -> Svg msg
viewInternal eventOptions selected gStyles rectStyles nameView personMatchIcon =
  let
    eventHandlers =
      ( case eventOptions.onContextMenu of
          Just attr ->
            [ attr ]

          Nothing -> []
      ) ++
      ( case eventOptions.onMouseDown of
          Just attr ->
            [ attr ]

          Nothing -> []
      ) ++
      ( case eventOptions.onMouseUp of
          Just msg ->
            [ Html.Events.onWithOptions "mouseup" { stopPropagation = True, preventDefault = False } Mouse.position |> Html.Attributes.map msg
            ]

          Nothing -> []
      ) ++
      ( case eventOptions.onClick of
          Just msg ->
            [ Html.Events.onWithOptions "click" { stopPropagation = True, preventDefault = False } (Decode.succeed msg)
            ]

          Nothing -> []
      ) ++
      ( case eventOptions.onStartEditingName of
          Just msg -> [ Html.Events.onDoubleClick msg ]

          Nothing -> []
      )
  in
    g
      ( gStyles )
      [ rect (rectStyles ++ eventHandlers) []
      , nameView
      , personMatchIcon
      , resizeGripView selected eventOptions.onStartResize
      ]


resizeGripView : Bool -> Maybe (Position -> msg) -> Svg msg
resizeGripView selected onStartResize =
  case onStartResize of
    Just msg ->
      (lazy resizeGripViewHelp selected)
        |> Svg.map msg

    Nothing ->
      text ""


resizeGripViewHelp : Bool -> Svg Position
resizeGripViewHelp selected =
  rect
    [ width "8"
    , height "8"
    , Html.Events.onWithOptions "mousedown" { stopPropagation = True, preventDefault = True } Mouse.position
    ]
    []


personMatchingView : Scale -> String -> Bool -> Svg msg
personMatchingView scale name personMatched =
  let
    ratio =
      Scale.imageToScreenRatio scale
  in
    if name /= "" && personMatched then
      circle [ cx "10", cy "10", r "10", fill "green" ] []
      -- div [ style (S.personMatched ratio) ] [ Lazy.lazy Icons.personMatched ratio ]
    else if name /= "" && not personMatched then
      circle [ cx "10", cy "10", r "10", fill "gray" ] []
      -- div [ style (S.personNotMatched ratio) ] [ Lazy.lazy Icons.personNotMatched ratio ]
    else
      text ""


objectLabelView : Bool -> String -> Float -> Scale -> Position -> Size -> String -> Svg msg
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
    foreignObject [ width "100", height "100", requiredExtensions "http://www.w3.org/1999/xhtml" ] [
    Html.div
      [ Html.Attributes.style styles
      , Html.Attributes.attribute "xmlns" "http://www.w3.org/1999/xhtml"
      ]
      [ if canBeEmoji then
          Emoji.view [] trimed
        else
          Html.span [] [ text trimed ]
      ]
    ]
    -- text_ [ x "0", y "0", fill color ] [ text trimed ]
    -- div
    --   [ style styles ]
    --   [ if canBeEmoji then
    --       Emoji.view [] trimed
    --     else
    --       span [] [ text trimed ]
    --   ]
