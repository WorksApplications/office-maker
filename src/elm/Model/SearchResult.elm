module Model.SearchResult exposing (..)

import Model.Object exposing (Object)

type alias Id = String

type alias SearchResult =
  { personId : Maybe Id
  , objectIdAndFloorId : Maybe (Object, Id)
  }


reorderResults : Maybe String -> List SearchResult -> List SearchResult
reorderResults thisFloorId results =
  let
    (inThisFloor, inOtherFloor, missing) =
      List.foldl (\({ personId, objectIdAndFloorId } as result) (this, other, miss) ->
        case objectIdAndFloorId of
          Just (eid, fid) ->
            if Just fid == thisFloorId then
              (result :: this, other, miss)
            else
              (this, result :: other, miss)
          Nothing ->
            (this, other, result :: miss)
      ) ([], [], []) results
  in
    inThisFloor ++ inOtherFloor ++ missing
