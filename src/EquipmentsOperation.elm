module EquipmentsOperation where

{- this module does not know Model or Floor -}

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

opposite : Direction -> Direction
opposite direction =
  case direction of
    Left -> Right
    Right -> Left
    Up -> Down
    Down -> Up

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

withinRange : (Equipment, Equipment) -> List Equipment -> List Equipment
withinRange range list =
  let
    (start, end) = range
    (startX, startY) = center start
    (endX, endY) = center end
    left = min startX endX
    right = max startX endX
    top = min startY endY
    bottom = max startY endY
    isContained e =
      let
        -- (x, y, w, h) = rectFloat e
        (centerX, centerY) = center e
      in
        centerX >= left &&
        centerX <= right &&
        centerY >= top &&
        centerY <= bottom
  in
    List.filter isContained list

bounds : List Equipment -> Maybe (Int, Int, Int, Int)
bounds list =
  let
    f e1 memo =
      let
        (x1, y1, w1, h1) = rect e1
        right1 = x1 + w1
        bottom1 = y1 + h1
      in
        case memo of
          Just (x, y, right, bottom) ->
            Just (min x x1, min y y1, max right right1, max bottom bottom1)
          Nothing ->
            Just (x1, y1, right1, bottom1)
  in
    List.foldl f Nothing list



bound : Direction -> Equipment -> Int
bound direction equipment =
  let
    (left, top, w, h) = rect equipment
    right = left + w
    bottom = top + h
  in
    case direction of
      Up -> top
      Down -> bottom
      Left -> left
      Right -> right

compareBoundBy : Direction -> Equipment -> Equipment -> Order
compareBoundBy direction e1 e2 =
  let
    (left1, top1, w1, h1) = rect e1
    right1 = left1 + w1
    bottom1 = top1 + h1
    (left2, top2, w2, h2) = rect e2
    right2 = left2 + w2
    bottom2 = top2 + h2
  in
    case direction of
      Up -> if top1 == top2 then EQ else if top1 < top2 then GT else LT
      Down -> if bottom1 == bottom2 then EQ else if bottom1 > bottom2 then GT else LT
      Left -> if left1 == left2 then EQ else if left1 < left2 then GT else LT
      Right -> if right1 == right2 then EQ else if right1 > right2 then GT else LT

minimumPartsOf : Direction -> List Equipment -> List Equipment
minimumPartsOf direction list =
  let
    f e memo =
      case memo of
        head :: _ ->
          case compareBoundBy direction e head of
            LT -> [e]
            EQ -> e :: memo
            GT -> memo
        _ -> [e]
  in
    List.foldl f [] list

maximumPartsOf : Direction -> List Equipment -> List Equipment
maximumPartsOf direction list =
  let
    f e memo =
      case memo of
        head :: _ ->
          case compareBoundBy direction e head of
            LT -> memo
            EQ -> e :: memo
            GT -> [e]
        _ -> [e]
  in
    List.foldl f [] list

restOfMinimumPartsOf : Direction -> List Equipment -> List Equipment
restOfMinimumPartsOf direction list =
  let
    minimumParts = minimumPartsOf direction list
  in
    List.filter (\e -> not (List.member e minimumParts)) list

restOfMaximumPartsOf : Direction -> List Equipment -> List Equipment
restOfMaximumPartsOf direction list =
  let
    maximumParts = maximumPartsOf direction list
  in
    List.filter (\e -> not (List.member e maximumParts)) list


expandOrShrink : Direction -> Equipment -> List Equipment -> List Equipment -> List Equipment
expandOrShrink direction primary current all =
  let
    (left0, top0, w0, h0) = rect primary
    right0 = left0 + w0
    bottom0 = top0 + h0
    (left, top, right, bottom) =
      Maybe.withDefault
        (left0, top0, right0, bottom0)
        (bounds current)
    isExpand =
      case direction of
        Up -> bottom == bottom0 && top <= top0
        Down -> top == top0 && bottom >= bottom0
        Left -> right == right0 && left <= left0
        Right -> left == left0 && right >= right0
  in
    if isExpand then
      let
        filter e1 =
          let
            (left1, top1, w1, h1) = rect e1
            right1 = left1 + w1
            bottom1 = top1 + h1
          in
            case direction of
              Up -> left1 >= left && right1 <= right && top1 < top
              Down -> left1 >= left && right1 <= right && bottom1 > bottom
              Left -> top1 >= top && bottom1 <= bottom && left1 < left
              Right -> top1 >= top && bottom1 <= bottom && right1 > right
        filtered = List.filter filter all
      in
        current ++ (minimumPartsOf direction filtered)
    else
      restOfMaximumPartsOf (opposite direction) current


pasteEquipments : (Int, Int) -> List (Equipment, Id) -> List Equipment -> List Equipment
pasteEquipments (baseX, baseY) copiedWithNewIds allEquipments =
  let
    (minX, minY) =
      List.foldl (\(equipment, newId) (minX, minY) ->
        let
          (x, y) = Equipments.position equipment
        in
          (Basics.min minX x, Basics.min minY y)
    ) (99999, 99999) copiedWithNewIds

    newEquipments =
      List.map (\(equipment, newId) ->
        let
          (x, y) = Equipments.position equipment
        in
          Equipments.copy newId (baseX + (x - minX), baseY + (y - minY)) equipment
    ) copiedWithNewIds
  in
    newEquipments

partiallyChange : (Equipment -> Equipment) -> List Id -> List Equipment -> List Equipment
partiallyChange f ids equipments =
  List.map (\equipment ->
    case equipment of
      Desk id _ _ _ ->
        if List.member id ids
        then f equipment
        else equipment
  ) equipments

moveEquipments : Int -> (Int, Int) -> List Id -> List Equipment -> List Equipment
moveEquipments gridSize (dx, dy) ids equipments =
  partiallyChange (\(Desk id (x, y, width, height) color name) ->
    let (newX, newY) = fitToGrid gridSize (x + dx, y + dy)
    in Desk id (newX, newY, width, height) color name
  ) ids equipments

findBy : (a -> Bool) -> List a -> Maybe a
findBy f list =
  List.head (List.filter f list)

findEquipmentById : List Equipment -> Id -> Maybe Equipment
findEquipmentById equipments id =
  findBy (\equipment -> id == (idOf equipment)) equipments

fitToGrid : Int -> (Int, Int) -> (Int, Int)
fitToGrid gridSize (x, y) =
  (x // gridSize * gridSize, y // gridSize * gridSize)

changeColor : String -> Equipment -> Equipment
changeColor color (Desk id rect _ name) = Desk id rect color name

changeName : String -> Equipment -> Equipment
changeName name (Desk id rect color _) = Desk id rect color name

idOf : Equipment -> Id
idOf (Desk id _ _ _) = id

nameOf : Equipment -> String
nameOf (Desk _ _ _ name) = name

--
