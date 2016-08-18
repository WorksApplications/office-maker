module Model.FloorInfo exposing (..)

import Model.Floor exposing (Floor)


type FloorInfo
  = Public Floor
  | PublicWithEdit Floor Floor
  | Private Floor


idOf : FloorInfo -> String
idOf info =
  case info of
    Public floor ->
      floor.id

    PublicWithEdit lastPublicFloor currentPrivateFloor ->
      currentPrivateFloor.id

    Private floor ->
      floor.id


findViewingFloor : String -> List FloorInfo -> Maybe Floor
findViewingFloor floorId list =
  case List.filter (\info -> idOf info == floorId) list of
    x :: _ ->
      case x of
        Public floor ->
          Just floor

        PublicWithEdit lastPublicFloor currentPrivateFloor ->
          Just lastPublicFloor

        Private floor ->
          Nothing
    _ ->
      Nothing


findFloor : String -> Int -> List FloorInfo -> Maybe Floor
findFloor floorId version list =
  case List.filter (\info -> idOf info == floorId) list of
    x :: _ ->
      case x of
        Public floor ->
          if floor.version == version then
            Just floor
          else
            Nothing

        PublicWithEdit lastPublicFloor currentPrivateFloor ->
          if lastPublicFloor.version == version then
            Just lastPublicFloor
          else if currentPrivateFloor.version == version then
            Just currentPrivateFloor
          else
            Nothing

        Private floor ->
          if floor.version == version then
            Just floor
          else
            Nothing
    _ ->
      Nothing
