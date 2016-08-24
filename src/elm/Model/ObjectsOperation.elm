module Model.ObjectsOperation exposing (..)

{- this module does not know Model or Floor -}

import Model.Object as Object exposing (..)
import Util.ListUtil exposing (..)


rectFloat : Object -> (Float, Float, Float, Float)
rectFloat e =
  let
    (x, y, w, h) = rect e
  in
    (toFloat x, toFloat y, toFloat w, toFloat h)


center : Object -> (Float, Float)
center e =
  let
    (x, y, w, h) = rectFloat e
  in
    ((x + w / 2), (y + h / 2))


linked : (number, number, number, number) -> (number, number, number, number) -> Bool
linked (x1, y1, w1, h1) (x2, y2, w2, h2) =
  x1 <= x2+w2 && x2 <= x1+w1 && y1 <= y2+h2 && y2 <= y1+h1


linkedByAnyOf : List Object -> Object -> Bool
linkedByAnyOf list newObject =
  List.any (\e ->
    linked (rect e) (rect newObject)
  ) list


island : List Object -> List Object -> List Object
island current rest =
  let
    (newObjects, rest') =
      List.partition (linkedByAnyOf current) rest
  in
    if List.isEmpty newObjects then
      current ++ newObjects
    else
      island (current ++ newObjects) rest'


type Direction = Up | Left | Right | Down


opposite : Direction -> Direction
opposite direction =
  case direction of
    Left -> Right
    Right -> Left
    Up -> Down
    Down -> Up


compareBy : Direction -> Object -> Object -> Order
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


lessBy : Direction -> Object -> Object -> Bool
lessBy direction from new =
  compareBy direction from new == LT


greaterBy : Direction -> Object -> Object -> Bool
greaterBy direction from new =
  compareBy direction from new == GT


minimumBy : Direction -> List Object -> Maybe Object
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


{-| Defines if given object can be selected next.
-}
filterCandidate : Direction -> Object -> Object -> Bool
filterCandidate direction from new =
    greaterBy direction from new


{-| Returns the next object toward given direction.
-}
nearest : Direction -> Object -> List Object -> Maybe Object
nearest direction from list =
  let
    filtered = List.filter (filterCandidate direction from) list
  in
    if List.isEmpty filtered then
      minimumBy direction list
    else
      minimumBy direction filtered


withinRange : (Object, Object) -> List Object -> List Object
withinRange range list =
  let
    (start, end) = range

    (startX, startY) = center start

    (endX, endY) = center end

    left = min startX endX

    right = max startX endX

    top = min startY endY

    bottom = max startY endY
  in
    withinRect (left, top) (right, bottom) list


withinRect : (Float, Float) -> (Float, Float) -> List Object -> List Object
withinRect (left, top) (right, bottom) list =
  let
    isContained e =
      let
        (centerX, centerY) = center e
      in
        centerX >= left &&
        centerX <= right &&
        centerY >= top &&
        centerY <= bottom
  in
    List.filter isContained list


bounds : List Object -> Maybe (Int, Int, Int, Int)
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


bound : Direction -> Object -> Int
bound direction object =
  let
    (left, top, w, h) = rect object

    right = left + w

    bottom = top + h
  in
    case direction of
      Up -> top
      Down -> bottom
      Left -> left
      Right -> right


compareBoundBy : Direction -> Object -> Object -> Order
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


minimumPartsOf : Direction -> List Object -> List Object
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


maximumPartsOf : Direction -> List Object -> List Object
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


restOfMinimumPartsOf : Direction -> List Object -> List Object
restOfMinimumPartsOf direction list =
  let
    minimumParts = minimumPartsOf direction list
  in
    List.filter (\e -> not (List.member e minimumParts)) list


restOfMaximumPartsOf : Direction -> List Object -> List Object
restOfMaximumPartsOf direction list =
  let
    maximumParts = maximumPartsOf direction list
  in
    List.filter (\e -> not (List.member e maximumParts)) list


expandOrShrink : Direction -> Object -> List Object -> List Object -> List Object
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


pasteObjects : (Int, Int) -> List (Object, Id) -> List Object -> List Object
pasteObjects (baseX, baseY) copiedWithNewIds allObjects =
  let
    (minX, minY) =
      List.foldl (\(object, newId) (minX, minY) ->
        let
          (x, y) = Object.position object
        in
          (Basics.min minX x, Basics.min minY y)
    ) (99999, 99999) copiedWithNewIds

    newObjects =
      List.map (\(object, newId) ->
        let
          (x, y) = Object.position object
        in
          Object.copy newId (baseX + (x - minX), baseY + (y - minY)) object
    ) copiedWithNewIds
  in
    newObjects


partiallyChange : (Object -> Object) -> List Id -> List Object -> List Object
partiallyChange f ids objects =
  List.map (\e ->
    if List.member (idOf e) ids then f e else e
  ) objects


moveObjects : Int -> (Int, Int) -> List Id -> List Object -> List Object
moveObjects gridSize (dx, dy) ids objects =
  partiallyChange (\e ->
    let
      (x, y, _, _) =
        rect e

      (newX, newY) =
        fitPositionToGrid gridSize (x + dx, y + dy)
    in
      Object.move (newX, newY) e
  ) ids objects


findObjectById : List Object -> Id -> Maybe Object
findObjectById objects id =
  findBy (\object -> id == (idOf object)) objects


fitPositionToGrid : Int -> (Int, Int) -> (Int, Int)
fitPositionToGrid gridSize (x, y) =
  (x // gridSize * gridSize, y // gridSize * gridSize)


fitSizeToGrid : Int -> (Int, Int) -> (Int, Int)
fitSizeToGrid gridSize (x, y) =
  (x // gridSize * gridSize, y // gridSize * gridSize)


backgroundColorProperty : List Object -> Maybe String
backgroundColorProperty selectedObjects =
  collectSameProperty backgroundColorOf selectedObjects


colorProperty : List Object -> Maybe String
colorProperty selectedObjects =
  collectSameProperty colorOf selectedObjects


shapeProperty : List Object -> Maybe Object.Shape
shapeProperty selectedObjects =
  collectSameProperty shapeOf selectedObjects


nameProperty : List Object -> Maybe String
nameProperty selectedObjects =
  collectSameProperty nameOf selectedObjects


fontSizeProperty : List Object -> Maybe Float
fontSizeProperty selectedObjects =
  collectSameProperty fontSizeOf selectedObjects


-- [red, green, green] -> Nothing
-- [blue, blue] -> Just blue
-- [] -> Nothing
collectSameProperty : (Object -> a) -> List Object -> Maybe a
collectSameProperty getProp selectedObjects =
  case List.head selectedObjects of
    Just e ->
      let
        firstProp = getProp e
      in
        List.foldl (\e maybeProp ->
          let
            prop = getProp e
          in
            case maybeProp of
              Just prop_ ->
                if prop == prop_ then Just prop else Nothing

              Nothing -> Nothing
        ) (Just firstProp) selectedObjects

    Nothing -> Nothing



--
