module Model.SearchResult exposing (..)

import Dict exposing (Dict)
import Model.Object as Object exposing (Object)
import Model.Person exposing (Person)

type alias Id = String
type alias FloorId = String
type alias PersonId = String
type alias PersonName = String

type SearchResult
  = Object Object FloorId
  | MissingPerson PersonId


type alias SearchResultsForOnePost =
  (Maybe PersonName, List SearchResult)


getPersonId : SearchResult -> Maybe Id
getPersonId result =
  case result of
    Object o _ ->
      Object.relatedPerson o

    MissingPerson personId ->
      Just personId


groupByPostAndReorder : Maybe String -> Dict String Person -> List SearchResult -> List SearchResultsForOnePost
groupByPostAndReorder thisFloorId personInfo results =
  groupByPost personInfo results
    |> List.map (\(maybePostName, results) -> (maybePostName, reorderResults thisFloorId results))


groupByPost : Dict String Person -> List SearchResult -> List SearchResultsForOnePost
groupByPost personInfo results =
  Dict.values <|
    groupBy (\result ->
      case getPersonId result of
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
      List.foldl (\result (this, other, miss) ->
        case result of
          Object _ floorId ->
            if Just floorId == thisFloorId then
              (result :: this, other, miss)
            else
              (this, result :: other, miss)

          MissingPerson _ ->
            (this, other, result :: miss)

      ) ([], [], []) results
  in
    inThisFloor ++ inOtherFloor ++ missing


mergeObjectInfo : String -> List Object -> List SearchResult -> List SearchResult
mergeObjectInfo currentFloorId objects results =
    List.concatMap (\result ->
      case result of
        Object object floorId ->
          if floorId == currentFloorId then
            case List.filter (\o -> Object.idOf object == Object.idOf o) objects of
              [] ->
                case Object.relatedPerson object of
                  Just personId ->
                    [ MissingPerson personId ]

                  Nothing ->
                    []

              _ ->
                [ result ]
          else
            [ result ]

        MissingPerson personId ->
          case List.filter (\object -> Object.relatedPerson object == Just personId) objects of
            [] ->
              [ result ]

            objects ->
              List.map (\object -> Object object currentFloorId) objects
            
    ) results
