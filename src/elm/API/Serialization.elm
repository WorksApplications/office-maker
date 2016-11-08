module API.Serialization exposing (..)

import Date

import Json.Encode as E exposing (Value)
import Json.Decode as D exposing ((:=), Decoder)
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded, custom)

import Util.DecodeUtil exposing (..)

import Model.Floor as Floor exposing (Floor, FloorBase)
import Model.FloorInfo as FloorInfo exposing (FloorInfo)
import Model.User as User exposing (User)
import Model.Person exposing (Person)
import Model.Object as Object exposing (..)
import Model.Prototype exposing (Prototype)
import Model.SearchResult as SearchResult exposing (SearchResult)
import Model.ColorPalette as ColorPalette exposing (ColorPalette)
import Model.ObjectsChange as ObjectsChange exposing (..)


decodeAuthToken : Decoder String
decodeAuthToken =
  D.object1 identity ("accessToken" := D.string)


decodeColors : Decoder ColorPalette
decodeColors =
  D.map makeColorPalette (D.list decodeColorEntity)


decodePrototypes : Decoder (List Prototype)
decodePrototypes =
  D.list decodePrototype


decodeFloors : Decoder (List Floor)
decodeFloors =
  D.list decodeFloor


decodeFloorInfoList : Decoder (List FloorInfo)
decodeFloorInfoList =
  D.list decodeFloorInfo


decodePeople : Decoder (List Person)
decodePeople =
  D.list decodePerson


encodeObject : Object -> Value
encodeObject object =
  let
    (x, y, w, h) =
      Object.rect object
  in
    E.object
      [ ("id", E.string (Object.idOf object))
      , ("floorId", E.string (Object.floorIdOf object))
      , ("floorVersion", Object.floorVersionOf object |> Maybe.map E.int |> Maybe.withDefault E.null)
      , ("updateAt", Object.updateAtOf object |> Maybe.map E.float |> Maybe.withDefault E.null)
      , ("type", E.string (if Object.isDesk object then "desk" else "label"))
      , ("x", E.int x)
      , ("y", E.int y)
      , ("width", E.int w)
      , ("height", E.int h)
      , ("backgroundColor", E.string (Object.backgroundColorOf object))
      , ("color", E.string (Object.colorOf object))
      , ("shape", E.string (encodeShape (Object.shapeOf object)))
      , ("name", E.string (Object.nameOf object))
      , ("fontSize", E.float (Object.fontSizeOf object))
      , ("personId",
          case Object.relatedPerson object of
            Just personId -> E.string personId
            Nothing -> E.null
        )
      ]


encodeShape : Shape -> String
encodeShape shape =
  case shape of
    Object.Rectangle ->
      "rectangle"

    Object.Ellipse ->
      "ellipse"


encodeObjectModification : ObjectModification -> Value
encodeObjectModification mod =
  E.object
    [ ("old", encodeObject mod.old)
    , ("new", encodeObject mod.new)
    ]


encodeFloor : Floor -> ObjectsChange -> Value
encodeFloor floor change =
  E.object
    [ ("id", E.string floor.id)
    , ("version", E.int floor.version)
    , ("name", E.string floor.name)
    , ("ord", E.int floor.ord)
    , ("added", E.list (List.map encodeObject change.added))
    , ("modified", E.list (List.map encodeObjectModification change.modified))
    , ("deleted", E.list (List.map encodeObject change.deleted))
    , ("width", E.int floor.width)
    , ("height", E.int floor.height)
    , ("realWidth", Maybe.withDefault E.null <| Maybe.map (E.int << fst) floor.realSize)
    , ("realHeight", Maybe.withDefault E.null <| Maybe.map (E.int << snd) floor.realSize)
    , ("image", Maybe.withDefault E.null <| Maybe.map E.string floor.image)
    , ("public", E.bool floor.public)
    ]


encodeLogin : String -> String -> Value
encodeLogin userId pass =
  E.object
    [ ("userId", E.string userId)
    , ("password", E.string pass)
    ]


decodeUser : Decoder User
decodeUser =
  D.oneOf
    [ D.object2
        (\role person ->
          if role == "admin" then User.admin person else User.general person
        )
        ("role" := D.string)
        ("person" := decodePerson)
    , D.succeed User.guest
    ]


decodeColorEntity : Decoder ColorEntity
decodeColorEntity =
  decode
    ColorEntity
    |> required "ord" D.int
    |> required "type" D.string
    |> required "color" D.string


decodePerson : Decoder Person
decodePerson =
  decode
    (\id name post mail tel image ->
      { id = id, name = name, post = post, mail = mail, tel = tel, image = image}
    )
    |> required "id" D.string
    |> required "name" D.string
    |> required "post" D.string
    |> optional' "mail" D.string
    |> optional' "tel" D.string
    |> optional' "image" D.string


 -- TODO andThen
decodeObject : Decoder Object
decodeObject =
  decode
    (\id floorId floorVersion updateAt tipe x y width height backgroundColor name personId fontSize color shape ->
      if tipe == "desk" then
        Object.initDesk id floorId floorVersion (x, y, width, height) backgroundColor name fontSize (Just updateAt) personId
      else
        Object.initLabel id floorId floorVersion (x, y, width, height) backgroundColor name fontSize (Just updateAt) color
          (if shape == "rectangle" then
            Object.Rectangle
          else
            Object.Ellipse
          )
    )
    |> required "id" D.string
    |> required "floorId" D.string
    |> optional' "floorVersion" D.int
    |> required "updateAt" D.float
    |> required "type" D.string
    |> required "x" D.int
    |> required "y" D.int
    |> required "width" D.int
    |> required "height" D.int
    |> required "backgroundColor" D.string
    |> required "name" D.string
    |> optional' "personId" D.string
    |> optional "fontSize" D.float Object.defaultFontSize
    |> required "color" D.string
    |> required "shape" D.string


decodeSearchResult : Decoder (Maybe SearchResult)
decodeSearchResult =
  decode
    (\maybePersonId maybeObjectAndFloorId ->
      case (maybePersonId, maybeObjectAndFloorId) of
        (_, Just (object, floorId)) ->
          Just <| SearchResult.Object object floorId

        (Just personId, Nothing) ->
          Just <| SearchResult.MissingPerson personId

        _ ->
          Nothing
    )
    |> optional' "personId" D.string
    |> optional' "objectAndFloorId" (D.tuple2 (,) decodeObject D.string)


decodeSearchResults : Decoder (List SearchResult)
decodeSearchResults =
  D.map (List.filterMap identity) (D.list decodeSearchResult)


decodeFloor : Decoder Floor
decodeFloor =
  decode
    (\id version name ord objects width height realWidth realHeight image public updateBy updateAt ->
      { id = id
      , version = version
      , name = name
      , ord = ord
      , objects = objects
      , width = width
      , height = height
      , image = image
      , realSize = Maybe.map2 (,) realWidth realHeight
      , public = public
      , update = Maybe.map2 (\by at -> { by = by, at = Date.fromTime at }) updateBy updateAt
      })
    |> required "id" D.string
    |> required "version" D.int
    |> required "name" D.string
    |> required "ord" D.int
    |> required "objects" (D.list decodeObject)
    |> required "width" D.int
    |> required "height" D.int
    |> optional' "realWidth" D.int
    |> optional' "realHeight" D.int
    |> optional' "image" D.string
    |> optional "public" D.bool False
    |> optional' "updateBy" D.string
    |> optional' "updateAt" D.float


decodeFloorBase : Decoder FloorBase
decodeFloorBase =
  decode
    (\id version name ord public ->
      { id = id
      , version = version
      , name = name
      , ord = ord
      , public = public
      })
    |> required "id" D.string
    |> required "version" D.int
    |> required "name" D.string
    |> required "ord" D.int
    |> optional "public" D.bool False


decodeFloorInfo : Decoder FloorInfo
decodeFloorInfo = D.map (\(lastFloor, lastFloorWithEdit) ->
  if lastFloorWithEdit.public then
    FloorInfo.Public lastFloorWithEdit
  else if lastFloor.public then
    FloorInfo.PublicWithEdit lastFloor lastFloorWithEdit
  else
    FloorInfo.Private lastFloorWithEdit
  ) (D.tuple2 (,) decodeFloorBase decodeFloorBase)


decodePrototype : Decoder Prototype
decodePrototype =
  decode
    (\id backgroundColor color name width height fontSize shape ->
      { id = id
      , name = name
      , backgroundColor = backgroundColor
      , color = color
      , width = width
      , height = height
      , fontSize = fontSize
      , shape = if shape == "Ellipse" then Ellipse else Rectangle
      , personId = Nothing
      }
    )
    |> required "id" D.string
    |> required "backgroundColor" D.string
    |> required "color" D.string
    |> required "name" D.string
    |> required "width" D.int
    |> required "height" D.int
    |> required "fontSize" D.float
    |> required "shape" D.string


encodePrototype : Prototype -> Value
encodePrototype { id, color, backgroundColor, name, width, height, fontSize, shape } =
  E.object
    [ ("id", E.string id)
    , ("color", E.string color)
    , ("backgroundColor", E.string backgroundColor)
    , ("name", E.string name)
    , ("width", E.int width)
    , ("height", E.int height)
    , ("fontSize", E.float fontSize)
    , ("shape", E.string (encodeShape shape))
    ]


encodeColorPalette : ColorPalette -> Value
encodeColorPalette colorPalette =
  encodeColorEntities (makeColorEntities colorPalette)


encodeColorEntities : List ColorEntity -> Value
encodeColorEntities entities =
  E.list (List.map encodeColorEntitity entities)


encodeColorEntitity : ColorEntity -> Value
encodeColorEntitity entity =
  E.object
    [ ("ord", E.int entity.ord)
    , ("color", E.string entity.color)
    , ("type", E.string entity.type_)
    ]


serializePrototype : Prototype -> String
serializePrototype prototype =
  E.encode 0 (encodePrototype prototype)


serializePrototypes : List Prototype -> String
serializePrototypes prototypes =
  E.encode 0 (E.list (List.map encodePrototype prototypes))


serializeColorPalette : ColorPalette -> String
serializeColorPalette colorPalette =
  E.encode 0 (encodeColorPalette colorPalette)


serializeFloor : Floor -> ObjectsChange -> String
serializeFloor floor change =
    E.encode 0 (encodeFloor floor change)


serializeLogin : String -> String -> String
serializeLogin userId pass =
    E.encode 0 (encodeLogin userId pass)


type alias ColorEntity =
  { ord : Int
  , type_ : String
  , color : String
  }


makeColorPalette : List ColorEntity -> ColorPalette
makeColorPalette entities =
  let
    sorted =
      List.sortBy (.ord) entities

    backgroundColors =
      List.filterMap (\e ->
        if e.type_ == "backgroundColor" then
          Just e.color
        else
          Nothing
      )
      sorted

    textColors =
      List.filterMap (\e ->
        if e.type_ == "color" then
          Just e.color
        else
          Nothing
      )
      sorted
  in
    { backgroundColors = backgroundColors
    , textColors = textColors
    }


makeColorEntities : ColorPalette -> List ColorEntity
makeColorEntities colorPalette =
  List.indexedMap (makeColorEntity "color") colorPalette.textColors ++
  List.indexedMap (makeColorEntity "backgroundColor") colorPalette.backgroundColors


makeColorEntity : String -> Int -> String -> ColorEntity
makeColorEntity type_ ord color =
  { ord = ord, color = color, type_ = type_ }
