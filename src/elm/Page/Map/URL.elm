module Page.Map.URL exposing (..)

import Dict
import Navigation exposing (Location)
import Util.UrlParser as UrlParser


type alias URL =
    { floorId : Maybe String
    , query : Maybe String
    , objectId : Maybe String
    , editMode : Bool
    }


parse : Location -> Result String URL
parse location =
    let
        floorId =
            getFloorId location

        dict =
            UrlParser.parseSearch location.search
    in
        Result.map
            (\floorId ->
                URL
                    floorId
                    (Dict.get "q" dict)
                    (Dict.get "object" dict)
                    (Dict.member "edit" dict)
            )
            floorId


getFloorId : Location -> Result String (Maybe String)
getFloorId location =
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


init : URL
init =
    { floorId = Nothing
    , query = Nothing
    , objectId = Nothing
    , editMode = False
    }


stringify : String -> URL -> String
stringify root { floorId, query, objectId, editMode } =
    let
        params =
            (List.filterMap
                (\( key, maybeValue ) -> Maybe.map (\v -> ( key, v )) maybeValue)
                [ ( "q", query )
                , ( "object", objectId )
                ]
            )
                ++ (if editMode then
                        [ ( "edit", "true" ) ]
                    else
                        []
                   )
    in
        case floorId of
            Just id ->
                root ++ stringifyParams params ++ "#" ++ id

            Nothing ->
                root ++ stringifyParams params


stringifyParams : List ( String, String ) -> String
stringifyParams params =
    if params == [] then
        ""
    else
        "?"
            ++ (String.join "&" <|
                    List.map (\( k, v ) -> k ++ "=" ++ v) params
               )



--
