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


-- createNewFloor : Task Error Int

saveEditingFloor : String -> Floor -> ObjectsChange -> Task Error Int
saveEditingFloor apiRoot floor change =
  putJson
    decodeFloorVersion
    (apiRoot ++ "/v1/floors/" ++ floor.id)
    (Http.string <| serializeFloor floor change)


publishEditingFloor : String -> String -> Task Error Int
publishEditingFloor apiRoot id =
  putJson
    decodeFloorVersion
    (apiRoot ++ "/v1/floors/" ++ id ++ "/public")
    (Http.string "")


getEditingFloor : String -> String -> Task Error Floor
getEditingFloor apiRoot id =
  getFloorHelp apiRoot True id


getFloor : String -> String -> Task Error Floor
getFloor apiRoot id =
  getFloorHelp apiRoot False id


getFloorHelp : String -> Bool -> String -> Task Error Floor
getFloorHelp apiRoot withPrivate id =
  let
    _ =
      if id == "" then
        Debug.crash "id is not defined"
      else
        ""

    url =
      Http.url
        (apiRoot ++ "/v1/floors/" ++ id)
        (if withPrivate then [("all", "true")] else [])
  in
    getJsonWithoutCache decodeFloor url


getFloorMaybe : String -> String -> Task Error (Maybe Floor)
getFloorMaybe apiRoot id =
  getFloor apiRoot id
  `Task.andThen` (\floor -> Task.succeed (Just floor))
  `Task.onError` \e -> case e of
    Http.BadResponse 404 _ -> Task.succeed Nothing
    _ -> Task.fail e


getFloorsInfo : String -> Bool -> Task Error (List FloorInfo)
getFloorsInfo apiRoot withPrivate =
  let
    url =
      Http.url
        (apiRoot ++ "/v1/floors")
        (if withPrivate then [("all", "true")] else [])
  in
    getJsonWithoutCache
      decodeFloorInfoList
      url


getPrototypes : String -> Task Error (List Prototype)
getPrototypes apiRoot =
    getJsonWithoutCache
      decodePrototypes
      (Http.url (apiRoot ++ "/v1/prototypes") [])


savePrototypes : String -> List Prototype -> Task Error ()
savePrototypes apiRoot prototypes =
  putJson
    noResponse
    (apiRoot ++ "/v1/prototypes")
    (Http.string <| serializePrototypes prototypes)


getColors : String -> Task Error ColorPalette
getColors apiRoot =
    getJsonWithoutCache
      decodeColors
      (Http.url (apiRoot ++ "/v1/colors") [])


getDiffSource : String -> String -> Task Error (Floor, Maybe Floor)
getDiffSource apiRoot id =
  getEditingFloor apiRoot id
  `Task.andThen` \current -> getFloorMaybe apiRoot id
  `Task.andThen` \prev -> Task.succeed (current, prev)


getAuth : String -> Task Error User
getAuth apiRoot =
  Http.get
    decodeUser
    (apiRoot ++ "/v1/self")


search : String -> Bool -> String -> Task Error (List SearchResult)
search apiRoot withPrivate query =
  let
    url =
      Http.url
        (apiRoot ++ "/v1/search/" ++ Http.uriEncode query)
        (if withPrivate then [("all", "true")] else [])
  in
    Http.get
      decodeSearchResults
      url


personCandidate : String -> String -> Task Error (List Person)
personCandidate apiRoot name =
  if String.isEmpty name then
    Task.succeed []
  else
    getJsonWithoutCache
      decodePersons <|
      (apiRoot ++ "/v1/candidates/" ++ Http.uriEncode name)


saveEditingImage : String -> Id -> File -> Task a ()
saveEditingImage apiRoot id file =
    HttpUtil.sendFile
      "PUT"
      (apiRoot ++ "/v1/images/" ++ id)
      file


getPerson : String -> Id -> Task Error Person
getPerson apiRoot id =
    Http.get
      decodePerson
      (apiRoot ++ "/v1/people/" ++ id)


getPersonByUser : String -> Id -> Task Error Person
getPersonByUser apiRoot id =
  let
    getUser =
      Http.get
        decodeUser
        (apiRoot ++ "/v1/users/" ++ id)
  in
    getUser
    `Task.andThen` (\user -> case user of
        User.Admin person -> Task.succeed person
        User.General person -> Task.succeed person
        User.Guest -> Debug.crash ("user " ++ id ++ " has no person")
      )


login : String -> String -> String -> String -> Task Error ()
login accountServiceRoot id tenantId pass =
    postJson
      noResponse
      (accountServiceRoot ++ "/v1/authentication")
      (Http.string <| serializeLogin id tenantId pass)


logout : String -> Task Error ()
logout accountServiceRoot =
    deleteJson
      noResponse
      (accountServiceRoot ++ "/v1/authentication")
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
