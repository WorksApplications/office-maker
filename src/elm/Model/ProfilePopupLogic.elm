module Model.ProfilePopupLogic exposing (..)

import Model.Scale as Scale exposing (Scale)
import Model.Object as Object exposing (Object)


type alias Position =
    { x : Int
    , y : Int
    }


centerTopScreenXYOfObject : Scale -> Position -> Object -> Position
centerTopScreenXYOfObject scale offset object =
  let
    (x, y, w, h) =
      Object.rect object
  in
    Scale.imageToScreenForPosition
      scale
      { x = offset.x + x + w//2
      , y = offset.y + y
      }


bottomScreenYOfObject : Scale -> Position -> Object -> Int
bottomScreenYOfObject scale offset object =
  let
    (x, y, w, h) =
      Object.rect object
  in
    Scale.imageToScreen scale (offset.y + y + h)


calcPopupLeftFromObjectCenter : Int -> Int -> Int
calcPopupLeftFromObjectCenter popupWidth objCenter =
  objCenter - (popupWidth // 2)


calcPopupRightFromObjectCenter : Int -> Int -> Int
calcPopupRightFromObjectCenter popupWidth objCenter =
  objCenter + (popupWidth // 2)


calcPopupTopFromObjectTop : Int -> Int -> Int
calcPopupTopFromObjectTop popupHeight objTop =
  objTop - (popupHeight + 10)


adjustOffset : (Int, Int) -> (Int, Int) -> Scale -> Position -> Object -> Position
adjustOffset (containerWidth, containerHeight) (popupWidth, popupHeight) scale offset object =
  let
    objCenterTop =
      centerTopScreenXYOfObject scale offset object

    left =
      calcPopupLeftFromObjectCenter popupWidth objCenterTop.x

    top =
      calcPopupTopFromObjectTop popupHeight objCenterTop.y

    right =
      calcPopupRightFromObjectCenter popupWidth objCenterTop.x

    bottom =
      bottomScreenYOfObject scale offset object

    offsetX_ =
      adjust scale containerWidth left right offset.x

    offsetY_ =
      adjust scale containerHeight top bottom offset.y
  in
    { x = offsetX_
    , y = offsetY_
    }


adjust : Scale -> Int -> Int -> Int -> Int -> Int
adjust scale length min max offset =
  if min < 0 then
    offset - Scale.screenToImage scale (min - 0)
  else if max > length then
    offset - Scale.screenToImage scale (max - length)
  else
    offset
