module Model.ProfilePopupLogic exposing (..)

import Model.Scale as Scale
import Model.Equipments as Equipments exposing (..)


centerTopScreenXYOfEquipment : Scale.Model -> (Int, Int) -> Equipment -> (Int, Int)
centerTopScreenXYOfEquipment scale (offsetX, offsetY) equipment =
  let
    (x, y, w, h) =
      rect equipment
  in
    Scale.imageToScreenForPosition scale (offsetX + x + w//2, offsetY + y)

bottomScreenYOfEquipment : Scale.Model -> (Int, Int) -> Equipment -> Int
bottomScreenYOfEquipment scale (offsetX, offsetY) equipment =
  let
    (x, y, w, h) =
      rect equipment
  in
    Scale.imageToScreen scale (offsetY + y + h)


calcPopupLeftFromEquipmentCenter : Int -> Int -> Int
calcPopupLeftFromEquipmentCenter popupWidth eqCenter =
  eqCenter - (popupWidth // 2)


calcPopupRightFromEquipmentCenter : Int -> Int -> Int
calcPopupRightFromEquipmentCenter popupWidth eqCenter =
  eqCenter + (popupWidth // 2)


calcPopupTopFromEquipmentTop : Int -> Int -> Int
calcPopupTopFromEquipmentTop popupHeight eqTop =
  eqTop - (popupHeight + 10)


adjustOffset : (Int, Int) -> (Int, Int) -> Scale.Model -> (Int, Int) -> Equipment -> (Int, Int)
adjustOffset (containerWidth, containerHeight) (popupWidth, popupHeight) scale (offsetX, offsetY) equipment =
  let
    (eqCenter, eqTop) =
      centerTopScreenXYOfEquipment scale (offsetX, offsetY) equipment

    left =
      calcPopupLeftFromEquipmentCenter popupWidth eqCenter

    top =
      calcPopupTopFromEquipmentTop popupHeight eqTop

    right =
      calcPopupRightFromEquipmentCenter popupWidth eqCenter

    bottom =
      bottomScreenYOfEquipment scale (offsetX, offsetY) equipment

    offsetX' =
      if left < 0 then
        offsetX - left
      else if right > containerWidth then
        offsetX - (right - containerWidth)
      else
        offsetX

    offsetY' =
      if top < 0 then
        offsetY - top
      else if bottom > containerHeight then
        offsetY - (bottom - containerHeight)
      else
        offsetY
  in
    (offsetX', offsetY')
