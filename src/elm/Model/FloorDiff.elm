module Model.FloorDiff exposing(..)

import Maybe
import Dict exposing (Dict)

import Model.Object as Object exposing (..)
import Model.Floor as Floor exposing (Floor)
import Model.ObjectsChange as ObjectsChange exposing (..)


type alias Options msg =
  { onClose : msg
  , onConfirm : msg
  , noOp : msg
  }


type alias PropChanges =
  List (String, String, String)


diff : Floor -> Maybe Floor -> (PropChanges, DetailedObjectsChange)
diff new old =
  ( diffPropertyChanges new old
  , diffObjects new.objects ( Maybe.withDefault Dict.empty (Maybe.map .objects old))
  )


diffPropertyChanges : Floor -> Maybe Floor -> List (String, String, String)
diffPropertyChanges current prev =
  case prev of
    Just prev ->
      propertyChangesHelp current prev

    -- FIXME completely wrong
    Nothing ->
      (if Floor.name current /= "" then [ ("Name", Floor.name current, "") ] else []) ++
      (case current.realSize of
        Just (w2, h2) ->
          [("Size", "(" ++ toString w2 ++ ", " ++ toString h2 ++ ")", "")]

        Nothing -> []
      )


propertyChangesHelp : Floor -> Floor -> List (String, String, String)
propertyChangesHelp current prev =
  let
    nameChange =
      if Floor.name current == Floor.name prev then
        []
      else
        [("Name", Floor.name current, Floor.name prev)]

    ordChange =
      if current.ord == prev.ord then
        []
      else
        [("Order", toString current.ord, toString prev.ord)]

    sizeChange =
      if current.realSize == prev.realSize then
        []
      else case (current.realSize, prev.realSize) of
        (Just (w1, h1), Just (w2, h2)) ->
          [("Size", "(" ++ toString w1 ++ ", " ++ toString h1 ++ ")", "(" ++ toString w2 ++ ", " ++ toString h2 ++ ")")]

        (Just (w1, h1), Nothing) ->
          [("Size", "(" ++ toString w1 ++ ", " ++ toString h1 ++ ")", "")]

        (Nothing, Just (w2, h2)) ->
          [("Size", "", "(" ++ toString w2 ++ ", " ++ toString h2 ++ ")")]

        _ ->
          [] -- should not happen

    imageChange =
      if current.image /= prev.image then
        [("Image", Maybe.withDefault "" current.image, Maybe.withDefault "" prev.image)]
      else
        []
  in
    nameChange ++ ordChange ++ sizeChange ++ imageChange


diffObjects : Dict ObjectId Object -> Dict ObjectId Object -> DetailedObjectsChange
diffObjects newObjects oldObjects =
  Dict.merge
    (\id new dict -> Dict.insert id (ObjectsChange.Added new) dict)
    (\id new old dict ->
      case diffObject new old of
        [] -> dict
        list -> Dict.insert id (ObjectsChange.Modified { new = new, old = old, changes = list }) dict)
    (\id old dict -> Dict.insert id (ObjectsChange.Deleted old) dict)
    newObjects
    oldObjects
    Dict.empty


-- TODO separate model and view
diffObject : Object -> Object -> List String
diffObject new old =
  let
    nameChange =
      if nameOf new /= nameOf old then
        Just ("name chaged: " ++ nameOf old ++ " -> " ++ nameOf new)
      else
        Nothing

    sizeChange =
      if rect new /= rect old then
        Just ("position/size chaged: " ++ toString (rect old) ++ " -> " ++ toString (rect new))
      else
        Nothing

    bgColorChange =
      if backgroundColorOf new /= backgroundColorOf old then
        Just ("background color chaged: " ++ backgroundColorOf old ++ " -> " ++ backgroundColorOf new)
      else
        Nothing

    colorChange =
      if colorOf new /= colorOf old then
        Just ("color chaged: " ++ colorOf old ++ " -> " ++ colorOf new)
      else
        Nothing

    fontSizeChange =
      if fontSizeOf new /= fontSizeOf old then
        Just ("font size chaged: " ++ (toString (fontSizeOf old)) ++ " -> " ++ (toString (fontSizeOf new)))
      else
        Nothing

    shapeChange =
      if shapeOf new /= shapeOf old then
        Just ("shape chaged: " ++ (toString (shapeOf old)) ++ " -> " ++ (toString (shapeOf new)))
      else
        Nothing

    relatedPersonChange =
      if relatedPerson new /= relatedPerson old then
        Just ("person chaged: " ++ (toString (relatedPerson old)) ++ " -> " ++ (toString (relatedPerson new)))
      else
        Nothing
  in
    List.filterMap
      identity
      [ nameChange
      , sizeChange
      , bgColorChange
      , colorChange
      , fontSizeChange
      , shapeChange
      , relatedPersonChange
      ]



--
