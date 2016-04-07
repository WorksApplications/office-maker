module Position where

import Equipments exposing (..)

rect : Equipment -> (Int, Int, Int, Int)
rect (Desk _ rect _ _) = rect

rectFloat : Equipment -> (Float, Float, Float, Float)
rectFloat e =
  let
    (x, y, w, h) = rect e
  in
    (toFloat x, toFloat y, toFloat w, toFloat h)

center : Equipment -> (Float, Float)
center e =
  let
    (x, y, w, h) = rectFloat e
  in
    ((x + w / 2), (y + h / 2))

linked : (number, number, number, number) -> (number, number, number, number) -> Bool
linked (x1, y1, w1, h1) (x2, y2, w2, h2) =
  x1 <= x2+w2 && x2 <= x1+w1 && y1 <= y2+h2 && y2 <= y1+h1

linkedByAnyOf : List Equipment -> Equipment -> Bool
linkedByAnyOf list newEquipment =
  List.any (\e ->
    linked (rect e) (rect newEquipment)
  ) list

island : List Equipment -> List Equipment -> List Equipment
island current rest =
  let
    (newEquipments, rest') =
      List.partition (linkedByAnyOf current) rest
  in
    if List.isEmpty newEquipments then
      current ++ newEquipments
    else
      island (current ++ newEquipments) rest'

type Direction = Up | Left | Right | Down

compareBy : Direction -> Equipment -> Equipment -> Order
compareBy direction from new =
  let
    (centerX, centerY) = center from
    (newCenterX, newCenterY) = center new
  in
    if (centerX, centerY) == (newCenterX, newCenterY) then
      EQ
    else
      let
        greater =
          case direction of
            Up ->
              (newCenterX < centerX) || (newCenterX == centerX && newCenterY < centerY)
            Down ->
              (newCenterX > centerX) || (newCenterX == centerX && newCenterY > centerY)
            Left ->
              (newCenterY < centerY) || (newCenterY == centerY && newCenterX < centerX)
            Right ->
              (newCenterY > centerY) || (newCenterY == centerY && newCenterX > centerX)
      in
        if greater then GT else LT

lessBy : Direction -> Equipment -> Equipment -> Bool
lessBy direction from new =
  compareBy direction from new == LT

greaterBy : Direction -> Equipment -> Equipment -> Bool
greaterBy direction from new =
  compareBy direction from new == GT

minimumBy : Direction -> List Equipment -> Maybe Equipment
minimumBy direction list =
  let
    f e1 memo =
      case memo of
        Just e ->
          if lessBy direction e e1 then
            Just e1
          else
            Just e
        Nothing ->
          Just e1
  in
    List.foldl f Nothing list

{-| Defines if given equipment can be selected next.
-}
filterCandidate : Direction -> Equipment -> Equipment -> Bool
filterCandidate direction from new =
    greaterBy direction from new

{-| Returns the next equipment toward given direction.
-}
nearest : Direction -> Equipment -> List Equipment -> Maybe Equipment
nearest direction from list =
  let
    filtered = List.filter (filterCandidate direction from) list
  in
    if List.isEmpty filtered then
      minimumBy direction list
    else
      minimumBy direction filtered
