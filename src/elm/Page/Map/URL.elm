module Page.Map.URL exposing (..)

import Dict


import Navigation

import Model.EditingFloor as EditingFloor
import Model.Mode as Mode exposing (Mode(..))
import Util.UrlParser as UrlParser

import Page.Map.Model as Model exposing (Model)


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


stringify : String -> URL -> String
stringify root { floorId, query, editMode } =
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
        root ++ stringifyParams params ++ "#" ++ id

      Nothing ->
        root ++ stringifyParams params


stringifyParams : List (String, String) -> String
stringifyParams params =
  if params == [] then
    ""
  else
    "?" ++
      ( String.join "&" <|
        List.map (\(k, v) -> k ++ "=" ++ v) params
      )


fromModel : Model -> URL
fromModel model =
  { floorId = Maybe.map (\floor -> (EditingFloor.present floor).id) model.floor
  , query =
      if String.length model.searchQuery == 0 then
        Nothing
      else
        Just model.searchQuery
  , editMode =
      Mode.isEditMode model.mode
  }


serialize : Model -> String
serialize =
  (stringify ".") << fromModel



--
