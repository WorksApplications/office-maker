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
    , getPersonByUser
    , getColors
    , getPrototypes
    , savePrototypes
    , Error
  )

import String
import Http
import Task exposing (Task)

import Util.HttpUtil as HttpUtil exposing (..)
import Util.File exposing (File)

import Model.Floor as Floor
import Model.FloorDiff as FloorDiff exposing (..)
import Model.FloorInfo as FloorInfo exposing (FloorInfo)
import Model.User as User exposing (User)
import Model.Person exposing (Person)
import Model.Object as Object exposing (..)
import Model.Floor as Floor exposing (ImageSource(..))
import Model.Prototypes exposing (Prototype)
import Model.Serialization exposing (..)
import Model.SearchResult exposing (SearchResult)
import Model.ColorPalette exposing (ColorPalette)

type alias Floor = Floor.Model

type alias Error = Http.Error


apiRoot : String
apiRoot = ""


-- createNewFloor : Task Error Int
-- createNewFloor =
--   postJson
--     decodeFloorVersion
--     (apiRoot ++ "/api/v1/floors")
--     (Http.string "")


saveEditingFloor : Floor -> ObjectsChange -> Task Error Int
saveEditingFloor floor change =
  putJson
    decodeFloorVersion
    (apiRoot ++ "/api/v1/floors/" ++ floor.id)
    (Http.string <| serializeFloor floor change)


publishEditingFloor : String -> Task Error Int
publishEditingFloor id =
  putJson
    decodeFloorVersion
    (apiRoot ++ "/api/v1/floors/" ++ id ++ "/public")
    (Http.string "")


getEditingFloor : String -> Task Error Floor
getEditingFloor = getFloorHelp True


getFloor : String -> Task Error Floor
getFloor = getFloorHelp False


getFloorHelp : Bool -> String -> Task Error Floor
getFloorHelp withPrivate id =
  let
    _ =
      if id == "" then
        Debug.crash "id is not defined"
      else
        ""

    url =
      Http.url
        (apiRoot ++ "/api/v1/floors/" ++ id)
        (if withPrivate then [("all", "true")] else [])
  in
    getJsonWithoutCache decodeFloor url


getFloorMaybe : String -> Task Error (Maybe Floor)
getFloorMaybe id =
  getFloor id
  `Task.andThen` (\floor -> Task.succeed (Just floor))
  `Task.onError` \e -> case e of
    Http.BadResponse 404 _ -> Task.succeed Nothing
    _ -> Task.fail e


getFloorsInfo : Bool -> Task Error (List FloorInfo)
getFloorsInfo withPrivate =
  let
    url =
      Http.url
        (apiRoot ++ "/api/v1/floors")
        (if withPrivate then [("all", "true")] else [])
  in
    getJsonWithoutCache
      decodeFloorInfoList
      url


getPrototypes : Task Error (List Prototype)
getPrototypes =
    getJsonWithoutCache
      decodePrototypes
      (Http.url (apiRoot ++ "/api/v1/prototypes") [])


savePrototypes : List Prototype -> Task Error ()
savePrototypes prototypes =
  putJson
    noResponse
    (apiRoot ++ "/api/v1/prototypes")
    (Http.string <| serializePrototypes prototypes)


getColors : Task Error ColorPalette
getColors =
    getJsonWithoutCache
      decodeColors
      (Http.url (apiRoot ++ "/api/v1/colors") [])


getDiffSource : String -> Task Error (Floor, Maybe Floor)
getDiffSource id =
  getEditingFloor id
  `Task.andThen` \current -> getFloorMaybe id
  `Task.andThen` \prev -> Task.succeed (current, prev)


getAuth : Task Error User
getAuth =
    Http.get
      decodeUser
      (apiRoot ++ "/api/v1/auth")


search : Bool -> String -> Task Error (List SearchResult)
search withPrivate query =
  let
    url =
      Http.url
        (apiRoot ++ "/api/v1/search/" ++ Http.uriEncode query)
        (if withPrivate then [("all", "true")] else [])
  in
    Http.get
      decodeSearchResults
      url


personCandidate : String -> Task Error (List Person)
personCandidate name =
  if String.isEmpty name then
    Task.succeed []
  else
    getJsonWithoutCache
      decodePersons <|
      (apiRoot ++ "/api/v1/candidates/" ++ Http.uriEncode name)


saveEditingImage : Id -> File -> Task a ()
saveEditingImage id file =
    HttpUtil.sendFile
      "PUT"
      (apiRoot ++ "/api/v1/images/" ++ id)
      file


getPerson : Id -> Task Error Person
getPerson id =
    Http.get
      decodePerson
      (apiRoot ++ "/api/v1/people/" ++ id)


getPersonByUser : Id -> Task Error Person
getPersonByUser id =
  let
    getUser =
      Http.get
        decodeUser
        (apiRoot ++ "/api/v1/users/" ++ id)
  in
    getUser
    `Task.andThen` (\user -> case user of
        User.Admin person -> Task.succeed person
        User.General person -> Task.succeed person
        User.Guest -> Debug.crash ("user " ++ id ++ " has no person")
      )


login : String -> String -> Task Error ()
login id pass =
    postJson
      noResponse
      (apiRoot ++ "/api/v1/login")
      (Http.string <| serializeLogin id pass)


logout : Task Error ()
logout =
    postJson
      noResponse
      (apiRoot ++ "/api/v1/logout")
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
