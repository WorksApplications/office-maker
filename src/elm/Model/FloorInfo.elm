module Model.FloorInfo exposing (..)

import Model.Floor as Floor


type alias Floor = Floor.Model


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
      case Debug.log "x" x of
        Public floor ->
          Just floor

        PublicWithEdit lastPublicFloor currentPrivateFloor ->
          Just lastPublicFloor

        Private floor ->
          Nothing
    _ ->
      Nothing
