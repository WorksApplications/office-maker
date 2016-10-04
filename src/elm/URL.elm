module URL exposing (..)

import Dict
import String
import Model.Model as Model exposing (Model, EditMode(..))
import Util.UrlParser as UrlParser
import Navigation

type alias URL =
  { floorId: Maybe String
  , query : Maybe String
  , editMode : Bool
  }


parse : Navigation.Location -> Result String URL
parse location =
  let
    floorId =
      if String.startsWith "#" location.hash then
        let
          id =
            String.dropLeft 1 location.hash
        in
          if String.length id == 36 then
            Ok (Just id)
          else if String.length id == 0 then
            Ok Nothing
          else
            Err ("invalid floorId: " ++ id)
      else
        Ok Nothing

    dict =
      UrlParser.parseSearch location.search
  in
    case floorId of
      Ok floorId ->
        Ok <|
          { floorId = floorId
          , query = Dict.get "q" dict
          , editMode = Dict.member "edit" dict
          }

      Err s ->
        Err s


init : URL
init =
  { floorId = Nothing
  , query = Nothing
  , editMode = False
  }


stringify : URL -> String
stringify { floorId, query, editMode } =
  let
    params =
      (List.filterMap
        (\(key, maybeValue) -> Maybe.map (\v -> (key, v)) maybeValue)
        [ ("q", query)
        ]
      ) ++ (if editMode then [ ("edit", "true") ] else [])
  in
    case floorId of
      Just id ->
        stringifyParams params ++ "#" ++ id

      Nothing ->
        stringifyParams params


stringifyParams : List (String, String) -> String
stringifyParams params =
    "?" ++
      ( String.join "&" <|
        List.map (\(k, v) -> k ++ "=" ++ v) params
      )


fromModel : Model -> URL
fromModel model =
  { floorId = model.selectedFloor
  , query =
      if String.length model.searchQuery == 0 then
        Nothing
      else
        Just model.searchQuery
  , editMode =
      case model.editMode of
        Viewing _ -> False
        _ -> True
  }


serialize : Model -> String
serialize =
  stringify << fromModel


updateQuery : String -> URL -> URL
updateQuery newQuery url =
  { url | query = Just newQuery }


updateEditMode : Bool -> URL -> URL
updateEditMode editMode url =
  { url | editMode = editMode }


updateFloorId : Maybe String -> URL -> URL
updateFloorId newId url =
  { url | floorId = newId }


hashFromFloorId : String -> String
hashFromFloorId floorId =
  "#" ++ floorId

--
