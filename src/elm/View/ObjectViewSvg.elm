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

import View.CommonStyles as CommonStyles
import View.Icons as Icons
import Model.Scale as Scale exposing (Scale)
import Page.Map.Emoji as Emoji
import Util.StyleUtil exposing (px)
import Util.HtmlUtil as HtmlUtil
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
viewDesk eventOptions showPersonMatch pos size color name fontSize selected isGhost scale personMatched =
  let
    personMatchIcon =
      if showPersonMatch then
        lazy2 personMatchingView name personMatched
      else
        text ""

    rectStyles =
      [ width (px size.width)
      , height (px size.height)
      , fill color
      , stroke (if selected then CommonStyles.selectColor else "black")
      , strokeWidth (if selected then "3" else "1.5")
      ]

    gStyles =
      [ transform ("translate(" ++ toString pos.x ++ "," ++ toString pos.y ++ ")")
      , fillOpacity (if isGhost then "0.5" else "1")
      ]

    nameView =
      objectLabelView size False "" fontSize pos size name
  in
    viewInternal eventOptions size selected scale gStyles rectStyles nameView personMatchIcon


viewLabel : EventOptions msg -> Position -> Size -> String -> String -> String -> Float -> Bool -> Bool -> Bool -> Bool -> Scale -> Svg msg
viewLabel eventOptions pos size backgroundColor fontColor name fontSize isEllipse selected isGhost rectVisible scale =
  let
    rectStyles =
      [ width (px size.width)
      , height (px size.height)
      , fill backgroundColor
      , stroke (if rectVisible then "black" else "none")
      , strokeDasharray "5,5"
      ]

    gStyles =
      [ transform ("translate(" ++ toString pos.x ++ "," ++ toString pos.y ++ ")")
      , fillOpacity (if isGhost then "0.5" else "1")
      ]

    nameView =
      objectLabelView size True fontColor fontSize pos size name
  in
    viewInternal eventOptions size selected scale gStyles rectStyles nameView (text "")


viewInternal : EventOptions msg -> Size -> Bool -> Scale -> List (Svg.Attribute msg) -> List (Svg.Attribute msg) -> Svg msg -> Svg msg -> Svg msg
viewInternal eventOptions size selected scale gStyles rectStyles nameView personMatchIcon =
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
      , resizeGripView size selected scale eventOptions.onStartResize
      ]


resizeGripView : Size -> Bool -> Scale -> Maybe (Position -> msg) -> Svg msg
resizeGripView containerSize selected scale onStartResize =
  case (selected, onStartResize) of
    (True, Just msg) ->
      (lazy3 resizeGripViewHelp containerSize selected scale)
        |> Svg.map msg

    _ ->
      text ""


resizeGripViewHelp : Size -> Bool -> Scale -> Svg Position
resizeGripViewHelp containerSize selected scale =
  let
    screenWidth =
      round <| 8 / Scale.imageToScreenRatio scale

    screenHeight =
      screenWidth
  in
    rect
      [ class "object-resize-grip"
      , width (toString screenWidth)
      , height (toString screenHeight)
      , x (toString <| containerSize.width - screenWidth // 2)
      , y (toString <| containerSize.height - screenHeight // 2)
      , Html.Events.onWithOptions "mousedown" { stopPropagation = True, preventDefault = True } Mouse.position
      , stroke "black"
      , fill "white"
      ]
    []


personMatchingView : String -> Bool -> Svg msg
personMatchingView name personMatched =
  if name == "" then
    text ""
  else
    g []
      [ circle
          [ pointerEvents "none"
          , cx "10"
          , cy "10"
          , r "10"
          , fill (if personMatched then "rgb(102, 170, 102)" else "rgb(204, 204, 204)")
          ]
          []
      , lazy (if personMatched then Icons.personMatched else Icons.personNotMatched) 1
      ]


objectLabelView : Size -> Bool -> String -> Float -> Position -> Size -> String -> Svg msg
objectLabelView containerSize canBeEmoji color fontSize_ screenPos screenSize name =
  let
    trimed =
      String.trim name

    -- inner s =
    --   if canBeEmoji then
    --     Emoji.view [] s
    --   else
    --     text s
  in
    text_
      [ y (toString <| toFloat containerSize.height / 2)
      , fill color
      , fontSize (toString fontSize_)
      , alignmentBaseline "middle"
      , dominantBaseline "middle"
      , textAnchor "middle"
      , pointerEvents "none"
      ]
      ( breakWords containerSize.width fontSize_ trimed
          |> coupleWithY 0.2
          |> List.map (\(s, y_) ->
            tspan [ dy y_, x (toString <| toFloat containerSize.width / 2) ] [ text s ]
          )
      )
    -- div
    --   [ style styles ]
    --   [ if canBeEmoji then
    --       Emoji.view [] trimed
    --     else
    --       span [] [ text trimed ]
    --   ]


coupleWithY : Float -> List String -> List (String, String)
coupleWithY spaceHeight lines =
  let
    len = List.length lines
    top = (toFloat len + spaceHeight * toFloat (len - 1)) * (-0.5) + 0.5
  in
    lines
      |> List.indexedMap (\i s ->
        if i == 0 then
          (s, toString (top + (1 + spaceHeight) * toFloat i) ++ "em")
        else
          (s, toString (1 + spaceHeight) ++ "em")
      )


breakWords : Int -> Float -> String -> List String
breakWords containerWidth fontSize s =
  breakWordsHelp containerWidth fontSize s []


breakWordsHelp : Int -> Float -> String -> List String -> List String
breakWordsHelp containerWidth fontSize s result =
  case cut containerWidth fontSize s of
    (left, Just right) ->
      breakWordsHelp containerWidth fontSize right (left :: result)

    (left, Nothing) ->
      left :: result
        |> List.reverse


cut : Int -> Float -> String -> (String, Maybe String)
cut containerWidth fontSize s =
  cutHelp containerWidth fontSize s 1


cutHelp : Int -> Float -> String -> Int -> (String, Maybe String)
cutHelp containerWidth fontSize s i =
  if String.length s < i then
    (s, Nothing)
  else
    let
      left =
        String.left i s

      measuredWidth =
        HtmlUtil.measureText "sans-self" fontSize left
    in
      if measuredWidth < toFloat containerWidth then
        cutHelp containerWidth fontSize s (i + 1)
      else
        ( String.left (Basics.max 1 (i - 1)) s
        , Just <| String.dropLeft (Basics.max 1 (i - 1)) s
        )
