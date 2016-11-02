module Page.Map.PrototypePreviewView exposing (view)

import Maybe

import Html exposing (..)
import Html.Attributes exposing (..)

import Util.HtmlUtil exposing (..)
import Util.ListUtil exposing (..)

import Model.Prototype exposing (Prototype)
import Model.Prototypes as Prototypes exposing (PositionedPrototype)

import View.Styles as S
import View.PrototypePreviewView as PrototypePreviewView

import Page.Map.Msg exposing (..)


view : List (Prototype, Bool) -> Html Msg
view prototypes =
  let
    containerWidth = 320 - (20 * 2) -- TODO
    containerHeight = 238 -- TODO

    selectedIndex =
      Maybe.withDefault 0 <|
      List.head <|
      List.filterMap (\((prototype, selected), index) -> if selected then Just index else Nothing) <|
      zipWithIndex prototypes

    buttonsView =
      buttons (List.length prototypes) selectedIndex

    box =
      PrototypePreviewView.view
        containerWidth
        containerHeight
        selectedIndex
        (List.map fst prototypes)

  in
    div
      [ style [("position", "relative")] ]
      ( box :: buttonsView )


buttons : Int -> Int -> List (Html Msg)
buttons prototypeLength selectedIndex =
  List.map (\isLeft ->
    let
      label = if isLeft then "<" else ">"
    in
      div
        [ style (S.prototypePreviewScroll isLeft)
        , onClick' (if isLeft then PrototypesMsg Prototypes.prev else PrototypesMsg Prototypes.next)
        ]
        [ text label ]
    )
  ( (if selectedIndex > 0 then [True] else []) ++
    (if selectedIndex < prototypeLength - 1 then [ False ] else [])
  )
