module View.PrototypePreviewView exposing (view)

import Maybe

import Html exposing (..)
import Html.Attributes exposing (..)

import View.Styles as S
import View.CanvasView as CanvasView

import Util.HtmlUtil exposing (..)
import Util.ListUtil exposing (..)

import Model exposing (..)
import Model.Scale as Scale
import Model.Prototype exposing (Prototype)
import Model.Prototypes as Prototypes exposing (StampCandidate)


view : List (Prototype, Bool) -> Bool -> Html Msg
view prototypes stampMode =
  let
    width = 320 - (20 * 2) -- TODO
    height = 238 -- TODO

    selectedIndex =
      Maybe.withDefault 0 <|
      List.head <|
      List.filterMap (\((prototype, selected), index) -> if selected then Just index else Nothing) <|
      zipWithIndex prototypes

    buttons' =
      buttons selectedIndex prototypes

    inner =
      div
        [ style (S.prototypePreviewViewInner width selectedIndex) ]
        (List.indexedMap (eachView (width, height)) prototypes)
  in
    div
      [ style (S.prototypePreviewView stampMode) ]
      ( inner :: buttons' )


eachView : (Int, Int) -> Int -> (Prototype, Bool) -> Html Msg
eachView (width, height) index (prototype, selected) =
  let
    (w, h) = prototype.size
    left = width // 2 - w // 2
    top = height // 2 - h // 2
  in
    snd <| CanvasView.temporaryStampView Scale.init False (prototype, (left + index * width, top))


buttons : Int -> List (Prototype, Bool) -> List (Html Msg)
buttons selectedIndex prototypes =
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
    (if selectedIndex < List.length prototypes - 1 then [ False ] else [])
  )
