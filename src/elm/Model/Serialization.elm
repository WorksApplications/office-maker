module Model.Serialization exposing (..)

import Date

import Json.Encode as Encode exposing (object, encode, list, string, int, bool, null, float, Value)
import Json.Decode as Decode exposing ((:=), object8, object7, object4, object2, oneOf, Decoder)
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded, custom)

import Util.DecodeUtil exposing (..)

import Model.Floor as Floor exposing (ImageSource(..))
import Model.FloorDiff as FloorDiff exposing (..)
import Model.FloorInfo as FloorInfo exposing (FloorInfo)
import Model.User as User exposing (User)
import Model.Person exposing (Person)
import Model.Object as Object exposing (..)
import Model.Prototype exposing (Prototype)
import Model.SearchResult exposing (SearchResult)
import Model.ColorPalette as ColorPalette exposing (ColorPalette, ColorEntity)

type alias Floor = Floor.Model


decodeAuthToken : Decoder String
decodeAuthToken =
  Decode.object1 identity ("accessToken" := Decode.string)


decodeFloorVersion : Decoder Int
decodeFloorVersion =
  Decode.object1 identity ("version" := Decode.int)


decodeColors : Decoder ColorPalette
decodeColors =
  Decode.map ColorPalette.init (Decode.list decodeColorEntity)


decodePrototypes : Decoder (List Prototype)
decodePrototypes =
  Decode.list decodePrototype


decodeFloors : Decoder (List Floor)
decodeFloors =
  Decode.list decodeFloor


decodeFloorInfoList : Decoder (List FloorInfo)
decodeFloorInfoList =
  Decode.list decodeFloorInfo


decodePersons : Decoder (List Person)
decodePersons =
  Decode.list decodePerson


encodeObject : Object -> Value
encodeObject e =
  case e of
    Desk id (x, y, width, height) backgroundColor name personId ->
      object
        [ ("id", string id)
        , ("type", string "desk")
        , ("x", int x)
        , ("y", int y)
        , ("width", int width)
        , ("height", int height)
        , ("backgroundColor", string backgroundColor)
        , ("color", string "#000")
        , ("shape", string "rectangle")
        , ("name", string name)
        , ("fontSize", float Object.defaultFontSize)
        , ("personId"
          , case personId of
              Just id -> string id
              Nothing -> null
          )
        ]

    Label id (x, y, width, height) bgColor name fontSize color shape ->
      object
        [ ("id", string id)
        , ("type", string "label")
        , ("x", int x)
        , ("y", int y)
        , ("width", int width)
        , ("height", int height)
        , ("backgroundColor", string bgColor)
        , ("name", string name)
        , ("fontSize", float fontSize)
        , ("color", string color)
        , ("shape", string (
          case shape of
            Object.Rectangle ->
              "rectangle"
            Object.Ellipse ->
              "ellipse"
          ))
        ]


encodeObjectModification : ObjectModification -> Value
encodeObjectModification mod =
  object
    [ ("old", encodeObject mod.old)
    , ("new", encodeObject mod.new)
    ]


encodeFloor : Floor -> ObjectsChange -> Value
encodeFloor floor change =
  let
    src =
      case floor.imageSource of
        LocalFile id _ _ -> string id
        URL url -> string url
        _ -> null
  in
    object
      [ ("id", string floor.id)
      , ("version", int floor.version)
      , ("name", string floor.name)
      , ("ord", int floor.ord)
      , ("added", list (List.map encodeObject change.added))
      , ("modified", list (List.map encodeObjectModification change.modified))
      , ("deleted", list (List.map encodeObject change.deleted))
      , ("width", int floor.width)
      , ("height", int floor.height)
      , ("realWidth", Maybe.withDefault null <| Maybe.map (int << fst) floor.realSize)
      , ("realHeight", Maybe.withDefault null <| Maybe.map (int << snd) floor.realSize)
      , ("image", src)
      , ("public", bool floor.public)
      ]


encodeLogin : String -> String -> String -> Value
encodeLogin userId tenantId pass =
  object
    [ ("userId", Encode.string userId)
    , ("tenantId", Encode.string tenantId)
    , ("password", Encode.string pass)
    ]


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


decodeColorEntity : Decoder ColorEntity
decodeColorEntity =
  decode
    ColorEntity
    |> required "id" Decode.string
    |> required "ord" Decode.int
    |> required "type" Decode.string
    |> required "color" Decode.string


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


 -- TODO andThen
decodeObject : Decoder Object
decodeObject =
  decode
    (\id tipe x y width height backgroundColor name personId fontSize color shape ->
      if tipe == "desk" then
        Desk id (x, y, width, height) backgroundColor name personId
      else
        Label id (x, y, width, height) backgroundColor name fontSize color
          (if shape == "rectangle" then
            Object.Rectangle
          else
            Object.Ellipse
          )
    )
    |> required "id" Decode.string
    |> required "type" Decode.string
    |> required "x" Decode.int
    |> required "y" Decode.int
    |> required "width" Decode.int
    |> required "height" Decode.int
    |> required "backgroundColor" Decode.string
    |> required "name" Decode.string
    |> optional' "personId" Decode.string
    |> optional "fontSize" Decode.float 0
    |> required "color" Decode.string
    |> required "shape" Decode.string


decodeSearchResult : Decoder SearchResult
decodeSearchResult =
  decode
    SearchResult
    |> optional' "personId" Decode.string
    |> optional' "objectIdAndFloorId" (Decode.tuple2 (,) decodeObject Decode.string)


decodeSearchResults : Decoder (List SearchResult)
decodeSearchResults =
  Decode.list decodeSearchResult


decodeFloor : Decoder Floor
decodeFloor =
  decode
    (\id version name ord objects width height realWidth realHeight src public updateBy updateAt ->
      { id = id
      , version = version
      , name = name
      , ord = ord
      , objects = objects
      , width = width
      , height = height
      , imageSource = Maybe.withDefault None (Maybe.map URL src)
      , realSize = Maybe.map2 (,) realWidth realHeight
      , public = public
      , update = Maybe.map2 (\by at -> { by = by, at = Date.fromTime at }) updateBy updateAt
      })
    |> required "id" Decode.string
    |> required "version" Decode.int
    |> required "name" Decode.string
    |> required "ord" Decode.int
    |> required "objects" (Decode.list decodeObject)
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
    (\id backgroundColor _ name width height _ _ ->
      { id = id, name = name, backgroundColor = backgroundColor, size = (width, height) }
    )
    |> required "id" Decode.string
    |> required "backgroundColor" Decode.string
    |> required "color" Decode.string
    |> required "name" Decode.string
    |> required "width" Decode.int
    |> required "height" Decode.int
    |> required "fontSize" Decode.float
    |> required "shape" Decode.string


encodePrototype : Prototype -> Value
encodePrototype { id, backgroundColor, name, size } =
  let
    (width, height) = size
  in
    object
      [ ("id", string id)
      , ("color", string backgroundColor)
      , ("name", string name)
      , ("width", int width)
      , ("height", int height)
      ]


serializePrototypes : List Prototype -> String
serializePrototypes prototypes =
  encode 0 (Encode.list (List.map encodePrototype prototypes))


serializeFloor : Floor -> ObjectsChange -> String
serializeFloor floor change =
    encode 0 (encodeFloor floor change)


serializeLogin : String -> String -> String -> String
serializeLogin userId tenantId pass =
    encode 0 (encodeLogin userId tenantId pass)
