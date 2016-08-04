module Model.ProfilePopupLogic exposing (..)

import Model.Scale as Scale
import Model.Object as Object exposing (..)


centerTopScreenXYOfObject : Scale.Model -> (Int, Int) -> Object -> (Int, Int)
centerTopScreenXYOfObject scale (offsetX, offsetY) object =
  let
    (x, y, w, h) =
      rect object
  in
    Scale.imageToScreenForPosition scale (offsetX + x + w//2, offsetY + y)


bottomScreenYOfObject : Scale.Model -> (Int, Int) -> Object -> Int
bottomScreenYOfObject scale (offsetX, offsetY) object =
  let
    (x, y, w, h) =
      rect object
  in
    Scale.imageToScreen scale (offsetY + y + h)


calcPopupLeftFromObjectCenter : Int -> Int -> Int
calcPopupLeftFromObjectCenter popupWidth eqCenter =
  eqCenter - (popupWidth // 2)


calcPopupRightFromObjectCenter : Int -> Int -> Int
calcPopupRightFromObjectCenter popupWidth eqCenter =
  eqCenter + (popupWidth // 2)


calcPopupTopFromObjectTop : Int -> Int -> Int
calcPopupTopFromObjectTop popupHeight eqTop =
  eqTop - (popupHeight + 10)


adjustOffset : (Int, Int) -> (Int, Int) -> Scale.Model -> (Int, Int) -> Object -> (Int, Int)
adjustOffset (containerWidth, containerHeight) (popupWidth, popupHeight) scale (offsetX, offsetY) object =
  let
    (eqCenter, eqTop) =
      centerTopScreenXYOfObject scale (offsetX, offsetY) object

    left =
      calcPopupLeftFromObjectCenter popupWidth eqCenter

    top =
      calcPopupTopFromObjectTop popupHeight eqTop

    right =
      calcPopupRightFromObjectCenter popupWidth eqCenter

    bottom =
      bottomScreenYOfObject scale (offsetX, offsetY) object

    offsetX' =
      adjust containerWidth left right offsetX

    offsetY' =
      adjust containerHeight top bottom offsetY
  in
    (offsetX', offsetY')


adjust : Int -> Int -> Int -> Int -> Int
adjust length min max offset =
  if min < 0 then
    offset - min
  else if max > length then
    offset - (max - length)
  else
    offset
