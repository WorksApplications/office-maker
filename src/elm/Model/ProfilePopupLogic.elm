module Model.ProfilePopupLogic exposing (..)

import Model.Scale as Scale exposing (Scale)
import Model.Object as Object exposing (..)


centerTopScreenXYOfObject : Scale -> (Int, Int) -> Object -> (Int, Int)
centerTopScreenXYOfObject scale (offsetX, offsetY) object =
  let
    (x, y, w, h) =
      rect object
  in
    Scale.imageToScreenForPosition scale (offsetX + x + w//2, offsetY + y)


bottomScreenYOfObject : Scale -> (Int, Int) -> Object -> Int
bottomScreenYOfObject scale (offsetX, offsetY) object =
  let
    (x, y, w, h) =
      rect object
  in
    Scale.imageToScreen scale (offsetY + y + h)


calcPopupLeftFromObjectCenter : Int -> Int -> Int
calcPopupLeftFromObjectCenter popupWidth objCenter =
  objCenter - (popupWidth // 2)


calcPopupRightFromObjectCenter : Int -> Int -> Int
calcPopupRightFromObjectCenter popupWidth objCenter =
  objCenter + (popupWidth // 2)


calcPopupTopFromObjectTop : Int -> Int -> Int
calcPopupTopFromObjectTop popupHeight objTop =
  objTop - (popupHeight + 10)


adjustOffset : (Int, Int) -> (Int, Int) -> Scale -> (Int, Int) -> Object -> (Int, Int)
adjustOffset (containerWidth, containerHeight) (popupWidth, popupHeight) scale (offsetX, offsetY) object =
  let
    (objCenter, objTop) =
      centerTopScreenXYOfObject scale (offsetX, offsetY) object

    left =
      calcPopupLeftFromObjectCenter popupWidth objCenter

    top =
      calcPopupTopFromObjectTop popupHeight objTop

    right =
      calcPopupRightFromObjectCenter popupWidth objCenter

    bottom =
      bottomScreenYOfObject scale (offsetX, offsetY) object

    offsetX' =
      adjust scale containerWidth left right offsetX

    offsetY' =
      adjust scale containerHeight top bottom offsetY
  in
    (offsetX', offsetY')


adjust : Scale -> Int -> Int -> Int -> Int -> Int
adjust scale length min max offset =
  if min < 0 then
    offset - Scale.screenToImage scale (min - 0)
  else if max > length then
    offset - Scale.screenToImage scale (max - length)
  else
    offset
