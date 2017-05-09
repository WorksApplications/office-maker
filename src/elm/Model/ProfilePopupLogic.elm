module Model.ProfilePopupLogic exposing (..)

import Model.Scale as Scale exposing (Scale)
import Model.Object as Object exposing (Object)
import CoreType exposing (..)


personPopupSize : Size
personPopupSize =
    Size 300 180


centerTopScreenXYOfObject : Scale -> Position -> Object -> Position
centerTopScreenXYOfObject scale offset object =
    let
        { x, y } =
            Object.positionOf object

        { width } =
            Object.sizeOf object
    in
        Scale.imageToScreenForPosition
            scale
            (Position (offset.x + x + width // 2) (offset.y + y))


bottomScreenYOfObject : Scale -> Position -> Object -> Int
bottomScreenYOfObject scale offset object =
    let
        { x, y } =
            Object.positionOf object

        { height } =
            Object.sizeOf object
    in
        Scale.imageToScreen scale (offset.y + y + height)


calcPopupLeftFromObjectCenter : Int -> Int -> Int
calcPopupLeftFromObjectCenter popupWidth objCenter =
    objCenter - (popupWidth // 2)


calcPopupRightFromObjectCenter : Int -> Int -> Int
calcPopupRightFromObjectCenter popupWidth objCenter =
    objCenter + (popupWidth // 2)


calcPopupTopFromObjectTop : Int -> Int -> Int
calcPopupTopFromObjectTop popupHeight objTop =
    objTop - (popupHeight + 10)


adjustOffset : Size -> Size -> Scale -> Position -> Object -> Position
adjustOffset containerSize popupSize scale offset object =
    let
        objCenterTop =
            centerTopScreenXYOfObject scale offset object

        left =
            calcPopupLeftFromObjectCenter popupSize.width objCenterTop.x

        top =
            calcPopupTopFromObjectTop popupSize.height objCenterTop.y

        right =
            calcPopupRightFromObjectCenter popupSize.width objCenterTop.x

        bottom =
            bottomScreenYOfObject scale offset object

        offsetX_ =
            adjust scale containerSize.width left right offset.x

        offsetY_ =
            adjust scale containerSize.height top bottom offset.y
    in
        Position offsetX_ offsetY_


adjust : Scale -> Int -> Int -> Int -> Int -> Int
adjust scale length min max offset =
    if min < 0 then
        offset - Scale.screenToImage scale (min - 0)
    else if max > length then
        offset - Scale.screenToImage scale (max - length)
    else
        offset
