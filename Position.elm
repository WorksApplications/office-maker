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

center : (Float, Float, Float, Float) -> (Float, Float)
center (x, y, w, h) = ((x + w / 2), (y + h / 2))

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

type Direction = Up | Left | Right | Down

{-| Returns if new position is more likely the next position to loop back to.
For example, if given direction is Down which indicates the direction the selection is moving toward,
next position is expected to be closer to top-left corner.
-}
closerToCorner : Direction -> (Float, Float) -> (Float, Float) -> Bool
closerToCorner direction (centerX, centerY) (newCenterX, newCenterY) =
  case direction of
    Up ->
      (newCenterX > centerX) || (newCenterX == centerX && newCenterY > centerY)
    Down ->
      (newCenterX < centerX) || (newCenterX == centerX && newCenterY < centerY)
    Left ->
      (newCenterY > centerY) || (newCenterY == centerY && newCenterX > centerX)
    Right ->
      (newCenterY < centerY) || (newCenterY == centerY && newCenterX < centerX)


{-| Returns the next equipment to loop back to.
For example, if given direction is Down which indicates the direction the selection is moving toward,
next position is expected to be closer to top-left corner.
-}
corner : Direction -> List Equipment -> Maybe Equipment
corner direction list =
  let
    f e1 memo =
      let
        (x1, y1, w1, h1) = rectFloat e1
        (centerX1, centerY1) = center (x1, y1, w1, h1)
      in
        case memo of
          Just (centerX, centerY, e) ->
            if closerToCorner direction (centerX, centerY) (centerX1, centerY1) then
              Just (centerX1, centerY1, e1)
            else
              Just (centerX, centerY, e)
          Nothing ->
            Just (centerX1, centerY1, e1)
    result =
      List.foldl f Nothing list
  in
    Maybe.map (\(_, _, e) -> e) result

{-| Defines if given equipment can be selected next.
-}
filterCandidate : Direction -> (Float, Float) -> Equipment -> Bool
filterCandidate direction (centerX, centerY) e =
  let
    (x1, y1, w1, h1) = rectFloat e
    (centerX1, centerY1) = center (x1, y1, w1, h1)
    cond1 =
      case direction of
        Up ->
          centerX1 < centerX || (centerX1 == centerX && centerY1 < centerY)
        Down ->
          centerX1 > centerX || (centerX1 == centerX && centerY1 > centerY)
        Left ->
          centerY1 < centerY || (centerY1 == centerY && centerX1 < centerX)
        Right ->
          centerY1 > centerY || (centerY1 == centerY && centerX1 > centerX)
    cond2 = (centerX, centerY) /= (centerX1, centerY1)
  in
    cond1 && cond2

{-| Returns the next equipment toward given direction.
-}
nearest : Direction -> Equipment -> List Equipment -> Maybe Equipment
nearest direction from list =
  let
    (Desk id (x0, y0, w0, h0) _ _) = from
    centerX = toFloat x0 + toFloat w0 / 2
    centerY = toFloat y0 + toFloat h0 / 2
    filter = filterCandidate direction (centerX, centerY)
    filtered = List.filter filter list
  in
    if List.isEmpty filtered then
      corner direction list
    else
      corner direction filtered
