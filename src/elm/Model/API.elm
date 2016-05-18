module Model.API exposing (
      getAuth
    , search
    , saveEditingFloor
    , publishEditingFloor
    , getEditingFloor
    , getFloor
    , getFloorsInfo
    , saveEditingImage
    , gotoTop
    , login
    , logout
    , goToLogin
    , goToLogout
    , personCandidate
    , getDiffSource
    , getPerson
    , Error
  ) -- where

import Date
import Http
import Json.Encode exposing (object, list, encode, string, int, bool, null, Value)
import Json.Decode as Decode exposing ((:=), object8, object7, object4, object2, oneOf, Decoder)
import Task exposing (Task)

import Util.HttpUtil as HttpUtil exposing (..)
import Util.File exposing (File)
import Util.DecodeUtil exposing (..)

import Model.Floor as Floor
import Model.User as User exposing (User)
import Model.Person exposing (Person)
import Model.Equipments as Equipments exposing (..)
import Model.Floor as Floor exposing (ImageSource(..))

import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded, custom)

type alias Floor = Floor.Model

type alias Error = Http.Error

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
    object [ ("id", string id), ("pass", string pass) ]

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
    |> optional' "realSize" (Decode.tuple2 (,) Decode.int Decode.int)
    |> optional' "src" Decode.string
    |> optional "public" Decode.bool False
    |> optional' "updateBy" Decode.string
    |> optional' "updateAt" Decode.float


serializeFloor : Floor -> String
serializeFloor floor =
    encode 0 (encodeFloor floor)


serializeLogin : String -> String -> String
serializeLogin id pass =
    encode 0 (encodeLogin id pass)


saveEditingFloor : Floor -> Task Error ()
saveEditingFloor floor =
  -- let
  --   _ = if floor.id == "tmp" then Debug.crash "cannot save tmp" else ""
  -- in
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
    getJsonWithoutCache
      decodeFloor
      ("/api/v1/floor/" ++ id ++ "/edit")

getFloorsInfo : Bool -> Task Error (List Floor)
getFloorsInfo withPrivate =
    getJsonWithoutCache
      (Decode.list decodeFloor)
      ("/api/v1/floors" ++ (if withPrivate then "?all=true" else ""))

getFloor : String -> Task Error Floor
getFloor id =
    getJsonWithoutCache
      decodeFloor
      ("/api/v1/floor/" ++ id)

getFloorMaybe : String -> Task Error (Maybe Floor)
getFloorMaybe id =
  getFloor id
  `Task.andThen` (\floor -> Task.succeed (Just floor))
  `Task.onError` \e -> case e of
    Http.BadResponse 404 _ -> Task.succeed Nothing
    _ -> Task.fail e


getDiffSource : String -> Task Error (Floor, Maybe Floor)
getDiffSource id =
  getEditingFloor id
  `Task.andThen` \current -> getFloorMaybe id
  `Task.andThen` \prev -> Task.succeed (current, prev)

getAuth : Task Error User
getAuth =
    Http.get
      decodeUser
      ("/api/v1/auth")

search : String -> Task Error (List (Equipment, String))
search query =
    Http.get
      (decodeSearchResult)
      ("/api/v1/search/" ++ query)

personCandidate : String -> Task Error (List Person)
personCandidate name =
    getJsonWithoutCache
      (Decode.list decodePerson)
      ("/api/v1/candidate/" ++ name)

saveEditingImage : Id -> File -> Task a ()
saveEditingImage id file =
    HttpUtil.sendFile
      "PUT"
      ("/api/v1/image/" ++ id)
      file

getPerson : Id -> Task Error Person
getPerson id =
    Http.get
      decodePerson
      ("/api/v1/people/" ++ id)


login : String -> String -> Task Error ()
login id pass =
    postJson
      (Decode.succeed ())
      ("/api/v1/login")
      (Http.string <| serializeLogin id pass)

logout : Task Error ()
logout =
    postJson
      (Decode.succeed ())
      ("/api/v1/logout")
      (Http.string "")

goToLogin : Task a ()
goToLogin =
  HttpUtil.goTo "/login"

goToLogout : Task a ()
goToLogout =
  HttpUtil.goTo "/logout"

gotoTop : Task a ()
gotoTop =
  HttpUtil.goTo "/"
