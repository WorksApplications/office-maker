module View.PrototypePreviewView exposing (view, singleView)

import Maybe

import Html exposing (..)
import Html.Attributes exposing (..)

import View.Styles as S
import View.ObjectView as ObjectView

import Util.HtmlUtil exposing (..)
import Util.ListUtil exposing (..)

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
    div [ style (S.prototypePreviewView containerWidth) ] [ inner ]


singleView : Int -> Int -> Prototype -> Html msg
singleView containerWidth containerHeight prototype =
  view containerWidth containerHeight 0 [ prototype ]


eachView : Int -> Int -> Int -> Int -> Prototype -> Html msg
eachView containerWidth containerHeight selectedIndex index prototype =
  let
    selected = selectedIndex == index
    (w, h) = prototype.size
    left = containerWidth // 2 - w // 2 + index * containerWidth
    top = containerHeight // 2 - h // 2
  in
    ObjectView.viewDesk
      ObjectView.noEvents
      False
      (left, top, w, h)
      prototype.backgroundColor
      prototype.name --name
      Object.defaultFontSize
      False -- selected
      False -- alpha
      Scale.default
      True -- disableTransition
      False -- personMatched
