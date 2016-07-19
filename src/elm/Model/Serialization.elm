module Model.Serialization exposing (..)

import Date

import Json.Encode as Encode exposing (object, encode, list, string, int, bool, null, Value)
import Json.Decode as Decode exposing ((:=), object8, object7, object4, object2, oneOf, Decoder)
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded, custom)

import Util.DecodeUtil exposing (..)

import Model.FloorInfo as FloorInfo exposing (FloorInfo)
import Model.User as User exposing (User)
import Model.Person exposing (Person)
import Model.Equipments as Equipments exposing (..)
import Model.Floor as Floor exposing (ImageSource(..))
import Model.Prototypes exposing (Prototype)
import Model.SearchResult exposing (SearchResult)
import Model.FloorInfo exposing (FloorInfo)

type alias Floor = Floor.Model

noResponse : Decoder ()
noResponse = Decode.succeed ()

decodeColors : Decoder (List String)
decodeColors = Decode.list Decode.string

decodePrototypes : Decoder (List Prototype)
decodePrototypes = Decode.list decodePrototype

decodeFloors : Decoder (List Floor)
decodeFloors = Decode.list decodeFloor

decodeFloorInfoList : Decoder (List FloorInfo)
decodeFloorInfoList = Decode.list decodeFloorInfo

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
      [ ("id", Maybe.withDefault null <| Maybe.map string <| floor.id)
      , ("name", string floor.name)
      , ("equipments", list <| List.map encodeEquipment floor.equipments)
      , ("width", int floor.width)
      , ("height", int floor.height)
      , ("realWidth", Maybe.withDefault null <| Maybe.map (int << fst) floor.realSize)
      , ("realHeight", Maybe.withDefault null <| Maybe.map (int << snd) floor.realSize)
      , ("image", src)
      , ("public", bool floor.public)
      ]

encodeLogin : String -> String -> Value
encodeLogin id pass =
    object [ ("id", Encode.string id), ("pass", Encode.string pass) ]

decodeUser : Decoder User
decodeUser =
  oneOf
  [ object2
      (\role person ->
        if role == "admin" then User.admin person else User.general person
      )
      ("role" := Decode.string)
      ("person" := decodePerson)
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
  decode
    (\id x y width height color name personId ->
      Desk id (x, y, width, height) color name personId
    )
    |> required "id" Decode.string
    |> required "x" Decode.int
    |> required "y" Decode.int
    |> required "width" Decode.int
    |> required "height" Decode.int
    |> required "color" Decode.string
    |> required "name" Decode.string
    |> optional' "personId" Decode.string

decodeSearchResult : Decoder SearchResult
decodeSearchResult =
  decode
    SearchResult
    |> optional' "personId" Decode.string
    |> optional' "equipmentIdAndFloorId" (Decode.tuple2 (,) decodeEquipment Decode.string)

decodeSearchResults : Decoder (List SearchResult)
decodeSearchResults =
  Decode.list decodeSearchResult


decodeFloor : Decoder Floor
decodeFloor =
  decode
    (\id name ord equipments width height realWidth realHeight src public updateBy updateAt ->
      { id = id
      , name = name
      , ord = ord
      , equipments = equipments
      , width = width
      , height = height
      , imageSource = Maybe.withDefault None (Maybe.map URL src)
      , realSize = Maybe.map2 (,) realWidth realHeight
      , public = public
      , update = Maybe.map2 (\by at -> { by = by, at = Date.fromTime at }) updateBy updateAt
      })
    |> optional' "id" Decode.string
    |> required "name" Decode.string
    |> required "ord" Decode.int
    |> required "equipments" (Decode.list decodeEquipment)
    |> required "width" Decode.int
    |> required "height" Decode.int
    |> optional' "realWidth" Decode.int
    |> optional' "realHeight" Decode.int
    |> optional' "image" Decode.string
    |> optional "public" Decode.bool False
    |> optional' "updateBy" Decode.string
    |> optional' "updateAt" Decode.float

decodeFloorInfo : Decoder FloorInfo
decodeFloorInfo = Decode.map (\(lastFloor, lastFloorWithEdit) ->
  if lastFloorWithEdit.public then
    FloorInfo.Public lastFloorWithEdit
  else if lastFloor.public then
    FloorInfo.PublicWithEdit lastFloor lastFloorWithEdit
  else
    FloorInfo.Private lastFloorWithEdit
  ) (Decode.tuple2 (,) decodeFloor decodeFloor)

decodePrototype : Decoder Prototype
decodePrototype =
  decode
    (\id color name width height -> (id, color, name, (width, height)))
    |> required "id" Decode.string
    |> required "color" Decode.string
    |> required "name" Decode.string
    |> required "width" Decode.int
    |> required "height" Decode.int

serializeFloor : Floor -> String
serializeFloor floor =
    encode 0 (encodeFloor floor)


serializeLogin : String -> String -> String
serializeLogin id pass =
    encode 0 (encodeLogin id pass)
