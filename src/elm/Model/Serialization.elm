module Model.Serialization exposing (..) -- where

import Date

import Json.Encode as Encode exposing (object, encode, list, string, int, bool, null, Value)
import Json.Decode as Decode exposing ((:=), object8, object7, object4, object2, oneOf, Decoder)
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded, custom)

import Util.DecodeUtil exposing (..)

import Model.Floor as Floor
import Model.User as User exposing (User)
import Model.Person exposing (Person)
import Model.Equipments as Equipments exposing (..)
import Model.Floor as Floor exposing (ImageSource(..))
import Model.Prototypes exposing (Prototype)

type alias Floor = Floor.Model

noResponse : Decoder ()
noResponse = Decode.succeed ()

decodeColors : Decoder (List String)
decodeColors = Decode.list Decode.string

decodePrototypes : Decoder (List Prototype)
decodePrototypes = Decode.list decodePrototype

decodeFloors : Decoder (List Floor)
decodeFloors = Decode.list decodeFloor

decodePersons : Decoder (List Person)
decodePersons = Decode.list decodePerson

encodeEquipment : Equipment -> Value
encodeEquipment (Desk id (x, y, width, height) color name personId) =
  object
    [ ("id", string id)
    , ("type", string "desk")
    , ("x", int x)
    , ("y", int y)
    , ("width", int width)
    , ("height", int height)
    , ("color", string color)
    , ("name", string name)
    , ("personId"
      , case personId of
          Just id -> string id
          Nothing -> null
      )
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
      , ("public", bool floor.public)
      ]

encodeLogin : String -> String -> Value
encodeLogin id pass =
    object [ ("id", Encode.string id), ("pass", Encode.string pass) ]

decodeUser : Decoder User
decodeUser =
  oneOf
  [ object2
      (\role name -> if role == "admin" then User.admin name else User.general name)
      ("role" := Decode.string)
      ("name" := Decode.string)
  , Decode.succeed User.guest
  ]

decodePerson : Decoder Person
decodePerson =
  decode
    (\id name org mail tel image ->
      { id = id, name = name, org = org, mail = mail, tel = tel, image = image}
    )
    |> required "id" Decode.string
    |> required "name" Decode.string
    |> required "org" Decode.string
    |> optional' "mail" Decode.string
    |> optional' "tel" Decode.string
    |> optional' "image" Decode.string

decodeEquipment : Decoder Equipment
decodeEquipment =
  object8
    (\id x y width height color name personId ->
      Desk id (x, y, width, height) color name personId
    )
    ("id" := Decode.string)
    ("x" := Decode.int)
    ("y" := Decode.int)
    ("width" := Decode.int)
    ("height" := Decode.int)
    ("color" := Decode.string)
    ("name" := Decode.string)
    ("personId" := Decode.maybe Decode.string)

decodeSearchResult : Decoder (List (Equipment, String))
decodeSearchResult =
  Decode.list (Decode.tuple2 (,) decodeEquipment Decode.string)

decodeFloor : Decoder Floor
decodeFloor =
  decode
    (\id name equipments width height realSize src public updateBy updateAt ->
      { id = id
      , name = name
      , equipments = equipments
      , width = width
      , height = height
      , imageSource = Maybe.withDefault None (Maybe.map URL src)
      , realSize = realSize
      , public = public
      , update = Maybe.map2 (\by at -> { by = by, at = Date.fromTime at }) updateBy updateAt
      })
    |> required "id" Decode.string
    |> required "name" Decode.string
    |> required "equipments" (Decode.list decodeEquipment)
    |> required "width" Decode.int
    |> required "height" Decode.int
    |> optional' "realSize" intSize
    |> optional' "src" Decode.string
    |> optional "public" Decode.bool False
    |> optional' "updateBy" Decode.string
    |> optional' "updateAt" Decode.float

decodePrototype : Decoder Prototype
decodePrototype =
  decode
    (,,,)
    |> required "id" Decode.string
    |> required "color" Decode.string
    |> required "name" Decode.string
    |> required "size" intSize

serializeFloor : Floor -> String
serializeFloor floor =
    encode 0 (encodeFloor floor)


serializeLogin : String -> String -> String
serializeLogin id pass =
    encode 0 (encodeLogin id pass)
