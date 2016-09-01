module View.ContextMenu exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)

import View.Styles as S

import Util.HtmlUtil exposing (..)

import Model exposing (..)

import InlineHover exposing (hover)


view : Model -> Html Msg
view model =
  case model.contextMenu of
    NoContextMenu ->
      text ""

    Object (x, y) id ->
      let
        forOneDesk =
          if [id] == model.selectedObjects then
            [ contextMenuItemView (SelectIsland id) "Select Island"
            , contextMenuItemView (RegisterPrototype id) "Register as stamp"
            , contextMenuItemView (Rotate id) "Rotate"
            ]
          else
            []

        common =
          [ contextMenuItemView (FirstNameOnly model.selectedObjects) "First name only"
          , contextMenuItemView (RemoveSpaces model.selectedObjects) "Remove Spaces"
          ]
      in
        div
          [ style (S.contextMenu (x, y + 37) (fst model.windowSize, snd model.windowSize) 2) -- TODO
          ]
          (forOneDesk ++ common)

    FloorInfo (x, y) id ->
      div
        [ style (S.contextMenu (x, y + 37) (fst model.windowSize, snd model.windowSize) 2) -- TODO
        ]
        [ contextMenuItemView (CopyFloor id) "Copy Floor"
        ]


contextMenuItemView : Msg -> String -> Html Msg
contextMenuItemView action text' =
  hover
    S.contextMenuItemHover
    div
    [ style S.contextMenuItem
    , onMouseDown' action
    ]
    [ text text' ]
