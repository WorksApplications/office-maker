module API (
      saveEditingFloor
    , publishEditingFloor
    , getEditingFloor
    , getFloor
    , saveEditingImage
    , gotoTop
    , login
    , Error
  ) where

import Equipments exposing (..)
import Floor exposing (ImageSource(..))
import Http
import Json.Encode exposing (object, list, encode, string, int, null, Value)
import Json.Decode as Decode exposing ((:=), object8, object7, Decoder)
import Task exposing (Task)
import Floor
import Util.HttpUtil as HttpUtil exposing (..)
import Util.File exposing (File)

type alias Floor = Floor.Model

type alias Error = Http.Error

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
  let
    src =
      case floor.imageSource of
        LocalFile id _ _ -> string id
        URL url -> string url
        _ -> null
  in
    object
      [ ("id", string floor.id)
      , ("name", string floor.name)
      , ("equipments", list <| List.map encodeEquipment floor.equipments)
      , ("width", int floor.width)
      , ("height", int floor.height)
      , ("realSize", case floor.realSize of
          Just (w, h) -> list [ int w, int h ]
          Nothing -> null)
      , ("src", src)
      ]

encodeLogin : String -> String -> Value
encodeLogin id pass =
    object [ ("id", string id), ("pass", string pass) ]

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

listToTuple2 : List a -> Maybe (a, a)
listToTuple2 list =
  case list of
    a :: b :: _ -> Just (a, b)
    _ -> Nothing


decodeFloor : Decoder Floor
decodeFloor =
  object7
    (\id name equipments width height realSize src ->
      { id = id
      , name = name
      , equipments = equipments
      , width = width
      , height = height
      , imageSource = Maybe.withDefault None (Maybe.map URL src)
      , realSize = Maybe.andThen realSize listToTuple2
      }) -- TODO
    ("id" := Decode.string)
    ("name" := Decode.string)
    ("equipments" := Decode.list decodeEquipment)
    ("width" := Decode.int)
    ("height" := Decode.int)
    (Decode.maybe ("realSize" := Decode.list Decode.int))
    (Decode.maybe ("src" := Decode.string))

serializeFloor : Floor -> String
serializeFloor floor =
    encode 0 (encodeFloor floor)


serializeLogin : String -> String -> String
serializeLogin id pass =
    encode 0 (encodeLogin id pass)


saveEditingFloor : Floor -> Task Error ()
saveEditingFloor floor =
    putJson
      (Decode.succeed ())
      ("/api/v1/floor/" ++ floor.id ++ "/edit")
      (Http.string <| serializeFloor floor)

publishEditingFloor : Floor -> Task Error ()
publishEditingFloor floor =
    postJson
      (Decode.succeed ())
      ("/api/v1/floor/" ++ floor.id)
      (Http.string <| serializeFloor floor)

getEditingFloor : String -> Task Error Floor
getEditingFloor id =
    Http.get
      decodeFloor
      ("/api/v1/floor/" ++ id ++ "/edit")

getFloor : String -> Task Error Floor
getFloor id =
    Http.get
      decodeFloor
      ("/api/v1/floor/" ++ id)

saveEditingImage : Id -> File -> Task a ()
saveEditingImage id file =
    HttpUtil.sendFile
      "PUT"
      ("/api/v1/image/" ++ id)
      file


login : String -> String -> Task Error ()
login id pass =
    postJson
      (Decode.succeed ())
      ("/api/v1/login")
      (Http.string <| serializeLogin id pass)

gotoTop : Task a ()
gotoTop =
  HttpUtil.goTo "/"
