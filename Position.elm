module Position where

import Equipments exposing (..)

x : Equipment -> Int
x (Desk id (x, _, _, _) _ _) = x

y : Equipment -> Int
y (Desk id (_, y, _, _) _ _) = y

w : Equipment -> Int
w (Desk id (_, _, w, _) _ _) = w

h : Equipment -> Int
h (Desk id (_, _, _, h) _ _) = h


island : List Equipment -> List Equipment -> List Equipment
island current rest =
  let
    match (Desk id (x1, y1, w1, h1) _ _) =
      List.any (\(Desk id (x2, y2, w2, h2) _ _) ->
        (x1 <= x2+w2 && x2 <= x1+w1 && y1 <= y2+h2 && y2 <= y1+h1)
      ) current
    (newEquipments, rest') = List.partition match rest
  in
    if List.isEmpty newEquipments then
      current ++ newEquipments
    else
      island (current ++ newEquipments) rest'


topLeft : List Equipment -> Maybe Equipment
topLeft list =
  let
    f e1 current =
      let
        x1 = toFloat (x e1)
        y1 = toFloat (y e1)
        w1 = toFloat (w e1)
        h1 = toFloat (h e1)
        centerX1 = (x1 + w1 / 2)
        centerY1 = (y1 + h1 / 2)
      in
        case current of
          Just (centerX, centerY, e) ->
            if (centerX1 < centerX) || (centerX1 == centerX && centerY1 < centerY) then
              Just (centerX1, centerY1, e1)
            else
              Just (centerX, centerY, e)
          Nothing ->
            Just (centerX1, centerY1, e1)
    result =
      List.foldl f Nothing list
  in
    case result of
      Just (_, _, e) -> Just e
      Nothing -> Nothing

nearestBelow : Equipment -> List Equipment -> Maybe Equipment
nearestBelow from list =
  let
    (Desk id (x0, y0, w0, h0) _ _) = from
    centerX = toFloat x0 + toFloat w0 / 2
    centerY = toFloat y0 + toFloat h0 / 2
    filter e =
      let
        x1 = toFloat (x e)
        y1 = toFloat (y e)
        w1 = toFloat (w e)
        h1 = toFloat (h e)
        centerX1 = (x1 + w1 / 2)
        centerY1 = (y1 + h1 / 2)
        dx1 = (x1 + w1 / 2) - centerX
        dy1 = (y1 + h1 / 2) - centerX
        cond1 = centerX1 > centerX || (centerX1 == centerX && centerY1 > centerY)
        cond2 = (centerX, centerY) /= (centerX1, centerY1)
      in
        cond1 && cond2
    filtered = List.filter filter list
  in
    if List.isEmpty filtered then
      topLeft list
    else
      topLeft filtered
