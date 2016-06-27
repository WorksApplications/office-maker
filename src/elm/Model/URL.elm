module Model.URL exposing (..)

import Dict
import String
import Util.UrlParser as UrlParser
import Navigation

type alias Model =
  { floorId: String
  , query : Maybe String
  , personId : Maybe String
  , editMode : Bool
  }

parse : Navigation.Location -> Result String Model
parse location =
  let
    floorId = String.dropLeft 1 location.hash
    dict = UrlParser.parseSearch location.search
  in
    if String.length floorId == 36 || String.length floorId == 0 then
      Ok
        { floorId = floorId
        , query = Dict.get "q" dict
        , personId = Dict.get "person" dict
        , editMode = Dict.member "edit" dict
        }
    else
      Err ("invalid floorId: " ++ floorId)

dummy : Model
dummy =
    { floorId = ""
    , query = Nothing
    , personId = Nothing
    , editMode = False
    }

stringify : Model -> String
stringify { floorId, query, personId, editMode } =
  let
    params =
      (List.filterMap
        (\(key, maybeValue) -> Maybe.map (\v -> (key, v)) maybeValue)
        [ ("q", query)
        , ("personId", personId)
        ]
      ) ++ (if editMode then [ ("edit", "true") ] else [])
  in
    stringifyParams params ++ "#" ++ floorId

stringifyParams : List (String, String) -> String
stringifyParams params =
    "?" ++
      ( String.join "&" <|
        List.map (\(k, v) -> k ++ "=" ++ v) params
      )

validate : Model -> Model
validate model =
  if String.length model.floorId == 36 || String.length model.floorId == 0 then
    model
  else
    updateFloorId Nothing model

updateQuery : String -> Model -> Model
updateQuery newQuery model =
  { model | query = Just newQuery }

updateEditMode : Bool -> Model -> Model
updateEditMode editMode model =
  { model | editMode = editMode }

updateFloorId : Maybe String -> Model -> Model
updateFloorId newId model =
  { model | floorId = Maybe.withDefault "" newId }

hashFromFloorId : Maybe String -> String
hashFromFloorId floorId =
  "#" ++ Maybe.withDefault "" floorId

--
