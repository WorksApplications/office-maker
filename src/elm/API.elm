module API(saveFloor, Floor) where

import Equipments exposing (..)
import Http
import Json.Encode exposing (object, list, encode, string, int, null, Value)
import Json.Decode
import Task exposing (Task)

type alias Id = String
type alias Floor =
  { id : Id
  , name : String
  , equipments: List Equipment
  , width : Int
  , height : Int
  , dataURL : Maybe String
  }

type alias APIError = Http.Error

put : Json.Decode.Decoder value -> String -> Http.Body -> Task Http.Error value
put decoder url body =
  let request =
    { verb = "PUT"
    , headers =
        [("Content-Type", "application/json; charset=utf-8")]
    , url = url
    , body = body
    }
  in
    Http.fromJson decoder (Http.send Http.defaultSettings request)

encodeEquipment : Equipment -> Value
encodeEquipment (Desk id (x, y, width, height) color name) =
  object
    [ ("id", string id)
    , ("type", string "desk")
    , ("x", int x)
    , ("y", int y)
    , ("width", int width)
    , ("height", int height)
    , ("color", string color)
    , ("name", string name)
    ]

encodeFloor : Floor -> Value
encodeFloor floor =
    object
      [ ("id", string floor.id)
      , ("name", string floor.name)
      , ("equipments", list <| List.map encodeEquipment floor.equipments)
      , ("width", int floor.width)
      , ("height", int floor.height)
      , ("dataURL", case floor.dataURL of
          Just s -> string s
          Nothing -> null
        )
      ]

serializeFloor : Floor -> String
serializeFloor floor =
    encode 0 (encodeFloor floor)

saveFloor : Floor -> Task APIError ()
saveFloor floor =
    put
      (Json.Decode.map (always ()) Json.Decode.value)
      ("/floor/" ++ floor.id)
      (Http.string <| serializeFloor floor)
