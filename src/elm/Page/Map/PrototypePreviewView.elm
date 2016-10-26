module Page.Map.PrototypePreviewView exposing (view)

import Maybe

import Html exposing (..)
import Html.Attributes exposing (..)

import View.Styles as S
import View.ObjectView as ObjectView

import Util.HtmlUtil exposing (..)
import Util.ListUtil exposing (..)

import Model.Scale as Scale exposing (Scale)
import Model.Prototype exposing (Prototype)
import Model.Prototypes as Prototypes exposing (StampCandidate)
import Model.Object as Object exposing (..)

import Page.Map.Msg exposing (..)

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
    snd <| temporaryStampView Scale.default False (prototype, (left + index * width, top))


temporaryStampView : Scale -> Bool -> StampCandidate -> (String, Html msg)
temporaryStampView scale selected (prototype, (left, top)) =
  let
    (deskWidth, deskHeight) = prototype.size
  in
    ( "temporary_" ++ toString left ++ "_" ++ toString top ++ "_" ++ toString deskWidth ++ "_" ++ toString deskHeight
    , ObjectView.viewDesk
        ObjectView.noEvents
        False
        (left, top, deskWidth, deskHeight)
        prototype.backgroundColor
        prototype.name --name
        Object.defaultFontSize
        selected
        False -- alpha
        scale
        True -- disableTransition
        False -- personMatched
    )


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
