module Model.FloorDiff exposing(..)

import Maybe
import Dict exposing (Dict)

import Model.Equipment as Equipment exposing (..)
import Model.Floor as Floor


type alias Floor = Floor.Model

type alias Options msg =
  { onClose : msg
  , onConfirm : msg
  , noOp : msg
  }

type alias EquipmentModification =
  { new : Equipment, old : Equipment, changes : List String }

type alias EquipmentsChange =
  { added : List Equipment
  , modified : List EquipmentModification
  , deleted : List Equipment
  }

type alias PropChanges =
  List (String, String, String)


noEquipmentsChange : EquipmentsChange
noEquipmentsChange =
  { added = [], modified = [], deleted = [] }


diff : Floor -> Maybe Floor -> (PropChanges, EquipmentsChange)
diff current prev =
  let
    newEquipments =
      Floor.equipments current

    oldEquipments =
      Maybe.withDefault [] <| Maybe.map Floor.equipments prev

  in
    ( diffPropertyChanges current prev
    , diffEquipments newEquipments oldEquipments
    )


diffPropertyChanges : Floor -> Maybe Floor -> List (String, String, String)
diffPropertyChanges current prev =
  case prev of
    Just prev ->
      propertyChangesHelp current prev

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
      if current.imageSource /= prev.imageSource then
        [("Image", "", "")] -- TODO how to describe?
      else
        []
  in
    nameChange ++ ordChange ++ sizeChange


diffEquipments : List Equipment -> List Equipment -> EquipmentsChange
diffEquipments newEquipments oldEquipments =
  let
    oldDict =
      List.foldl (\e dict -> Dict.insert (idOf e) e dict) Dict.empty oldEquipments

    f new (dict, add, modify) =
      case Dict.get (idOf new) dict of
        Just old ->
          ( Dict.remove (idOf new) dict, add,
            case diffEquipment new old of
              [] -> modify
              list -> { new = new, old = old, changes = list } :: modify
          )

        Nothing ->
          (dict, new :: add, modify)

    (ramainingOldDict, add, modify) =
      List.foldl f (oldDict, [], []) newEquipments

    delete =
      Dict.values ramainingOldDict
  in
    { added = add
    , modified = modify
    , deleted = delete
    }


-- TODO separate model and view
diffEquipment : Equipment -> Equipment -> List String
diffEquipment new old =
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
