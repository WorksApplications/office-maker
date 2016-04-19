module API(saveFloor, getFloor, Floor, Error) where

import Equipments exposing (..)
import Floor exposing (ImageSource(..))
import Http
import Json.Encode exposing (object, list, encode, string, int, null, Value)
import Json.Decode as Decode exposing ((:=), object8, object7, Decoder)
import Task exposing (Task)
import Floor

type alias Floor = Floor.Model

type alias Error = Http.Error

put : Decoder value -> String -> Http.Body -> Task Http.Error value
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
      , ("imageSource", string "/dummy.jpg")
      ]

decodeEquipment : Decoder Equipment
decodeEquipment =
  object7
    (\id x y width height color name -> Desk id (x, y, width, height) color name)
    ("id" := Decode.string)
    ("x" := Decode.int)
    ("y" := Decode.int)
    ("width" := Decode.int)
    ("height" := Decode.int)
    ("color" := Decode.string)
    ("name" := Decode.string)

decodeFloor : Decoder Floor
decodeFloor =
  object8
    (\id name equipments width height realWidth realHeight src ->
      { id = id
      , name = name
      , equipments = equipments
      , width = width
      , height = height
      , imageSource = Maybe.withDefault None (Maybe.map URL src)
      , realSize = realWidth `Maybe.andThen` (\w -> realHeight `Maybe.andThen` (\h -> Just (w, h)))
      }) -- TODO
    ("id" := Decode.string)
    ("name" := Decode.string)
    ("equipments" := Decode.list decodeEquipment)
    ("width" := Decode.int)
    ("height" := Decode.int)
    (Decode.maybe ("realWidth" := Decode.int))
    (Decode.maybe ("realHeight" := Decode.int))
    (Decode.maybe ("src" := Decode.string))

serializeFloor : Floor -> String
serializeFloor floor =
    encode 0 (encodeFloor floor)

saveFloor : Floor -> Task Error ()
saveFloor floor =
    put
      (Decode.map (always ()) Decode.value)
      ("/floor/" ++ floor.id)
      (Http.string <| serializeFloor floor)

getFloor : String -> Task Error Floor
getFloor id =
    Http.get
      decodeFloor
      ("/floor/" ++ id)

-- reserveId : TODO
