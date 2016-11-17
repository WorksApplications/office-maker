module View.ContextMenu exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)

import View.Styles as S
import Util.HtmlUtil exposing (..)
import InlineHover exposing (hover)


type alias Position =
  { x : Int
  , y : Int
  }


type alias Size =
  { width : Int
  , height : Int
  }


view : List (msg, String, Maybe String) -> Size -> Position -> Html msg
view items windowSize { x, y } =
  div
    [ style (S.contextMenu (x, y) (windowSize.width, windowSize.height) (calculateHeight items))
    ]
    (List.map itemView items)


calculateHeight : List (msg, String, Maybe String) -> Int
calculateHeight items =
  items
    |> List.map (\(_, _, annotation) ->
      case annotation of
        Just _ ->
          S.contextMenuItemHeightWithAnnotation

        Nothing ->
          S.contextMenuItemHeight
      )
    |> List.sum


itemView : (msg, String, Maybe String) -> Html msg
itemView (msg, text_, annotation) =
  case annotation of
    Just ann ->
      hover S.contextMenuItemHover div
        [ style (S.contextMenuItem True)
        , onMouseDown' msg
        ]
        [ text text_
        , div [ style S.contextMenuItemAnnotation ] [ text ann ]
        ]

    Nothing ->
      hover S.contextMenuItemHover div
        [ style (S.contextMenuItem False)
        , onMouseDown' msg
        ]
        [ text text_ ]
