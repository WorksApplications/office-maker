module View.PrototypePreviewView exposing (view, singleView, emptyView)

import Html exposing (..)
import Html.Attributes exposing (..)

import View.Styles as S
import View.ObjectView as ObjectView

import Model.Scale as Scale exposing (Scale)
import Model.Prototype exposing (Prototype)
import Model.Object as Object exposing (..)


view : Int -> Int -> Int -> List Prototype -> Html msg
view containerWidth containerHeight selectedIndex prototypes =
  let
    inner =
      div
        [ style (S.prototypePreviewViewInner containerWidth selectedIndex) ]
        (List.indexedMap (eachView containerWidth containerHeight selectedIndex) prototypes)
  in
    div [ style (S.prototypePreviewView containerWidth containerHeight) ] [ inner ]


singleView : Int -> Int -> Prototype -> Html msg
singleView containerWidth containerHeight prototype =
  view containerWidth containerHeight 0 [ prototype ]


emptyView : Int -> Int -> Html msg
emptyView containerWidth containerHeight =
  view containerWidth containerHeight 0 []


eachView : Int -> Int -> Int -> Int -> Prototype -> Html msg
eachView containerWidth containerHeight selectedIndex index prototype =
  let
    selected = selectedIndex == index
    left = containerWidth // 2 - prototype.width // 2 + index * containerWidth
    top = containerHeight // 2 - prototype.height // 2
  in
    ObjectView.viewDesk
      ObjectView.noEvents
      False
      (left, top, prototype.width, prototype.height)
      prototype.backgroundColor
      prototype.name --name
      prototype.fontSize
      False -- selected
      False -- alpha
      Scale.default
      True -- disableTransition
      False -- personMatched
