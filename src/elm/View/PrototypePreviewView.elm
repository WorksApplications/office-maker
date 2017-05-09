module View.PrototypePreviewView exposing (view, singleView, emptyView)

import Html exposing (..)
import Html.Attributes exposing (..)
import Svg exposing (Svg)
import Svg.Attributes
import View.Styles as S
import View.ObjectView as ObjectView
import Model.Scale as Scale exposing (Scale)
import Model.Prototype exposing (Prototype)
import CoreType exposing (..)


view : Size -> Int -> List Prototype -> Html msg
view containerSize selectedIndex prototypes =
    let
        inner =
            Svg.svg
                [ Svg.Attributes.width (toString <| containerSize.width * 4)
                , Svg.Attributes.height (toString containerSize.height)
                , style (S.prototypePreviewViewInner containerSize selectedIndex)
                ]
                (List.indexedMap (eachView containerSize selectedIndex) prototypes)
    in
        div [ style (S.prototypePreviewView containerSize.width containerSize.height) ] [ inner ]


singleView : Size -> Prototype -> Html msg
singleView containerSize prototype =
    view containerSize 0 [ prototype ]


emptyView : Size -> Html msg
emptyView containerSize =
    view containerSize 0 []


eachView : Size -> Int -> Int -> Prototype -> Html msg
eachView containerSize selectedIndex index prototype =
    let
        selected =
            selectedIndex == index

        left =
            containerSize.width // 2 - prototype.width // 2 + index * containerSize.width

        top =
            containerSize.height // 2 - prototype.height // 2
    in
        ObjectView.viewDesk
            ObjectView.noEvents
            False
            (Position left top)
            (Size prototype.width prototype.height)
            prototype.backgroundColor
            prototype.name
            --name
            prototype.fontSize
            False
            -- selected
            False
            -- alpha
            (Scale.init 0)
            False



-- personMatched
