module View.ContextMenu exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)

import View.Styles as S
import Util.HtmlUtil exposing (..)
import InlineHover exposing (hover)


view : List (msg, String) -> (Int, Int) -> (Int, Int) -> Html msg
view items windowSize (x, y) =
  div
    [ style (S.contextMenu (x, y + 37) windowSize (List.length items)) -- TODO
    ]
    (List.map itemView items)


itemView : (msg, String) -> Html msg
itemView (msg, text_) =
  hover
    S.contextMenuItemHover
    div
    [ style S.contextMenuItem
    , onMouseDown' msg
    ]
    [ text text_ ]
