module Model.SearchResult exposing (..)

import Dict exposing (Dict)
import Model.Object exposing (Object)
import Model.Person exposing (Person)

type alias Id = String

type alias SearchResult =
  { personId : Maybe Id
  , objectIdAndFloorId : Maybe (Object, Id)
  }


type alias SearchResultsForOnePost =
  (Maybe String, List SearchResult)


groupByPostAndReorder : Maybe String -> Dict String Person -> List SearchResult -> List SearchResultsForOnePost
groupByPostAndReorder thisFloorId personInfo results =
  groupByPost personInfo results
    |> List.map (\(maybePostName, results) -> (maybePostName, reorderResults thisFloorId results))


groupByPost : Dict String Person -> List SearchResult -> List SearchResultsForOnePost
groupByPost personInfo results =
  Dict.values <|
    groupBy (\r ->
      case r.personId of
        Just id ->
          case Dict.get id personInfo of
            Just person ->
              (person.post, Just person.post)

            Nothing ->
              ("", Nothing)

        Nothing ->
          ("", Nothing)
      ) results


groupBy : (a -> (comparable, b)) -> List a -> Dict comparable (b, List a)
groupBy f list =
  List.foldr (\a dict ->
    let
      (key, realKey) = f a
    in
      Dict.update key (\maybeValue ->
        case maybeValue of
          Just (realKey, value) ->
            Just (realKey, a :: value)

          Nothing ->
            Just (realKey, [a])
        ) dict
    ) Dict.empty list


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


mergeObjectInfo : List Object -> List SearchResult -> List SearchResult
mergeObjectInfo objects results = results -- TODO implement
