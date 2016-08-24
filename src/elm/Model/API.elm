module Model.API exposing (
      getAuth
    , search
    , saveEditingFloor
    , publishEditingFloor
    , getEditingFloor
    , getFloor
    , getFloorOfVersion
    , getFloorsInfo
    , saveEditingImage
    , gotoTop
    , login
    , goToLogin
    , goToLogout
    , personCandidate
    , getDiffSource
    , getPerson
    , getPersonByUser
    , getColors
    , getPrototypes
    , savePrototypes
    , Config
    , Error
  )

import String
import Http
import Task exposing (Task)

import Util.HttpUtil as HttpUtil exposing (..)
import Util.File exposing (File)

import Model.Floor as Floor exposing (Floor)
import Model.FloorDiff as FloorDiff exposing (..)
import Model.FloorInfo as FloorInfo exposing (FloorInfo)
import Model.User as User exposing (User)
import Model.Person exposing (Person)
import Model.Object as Object exposing (..)
import Model.Floor as Floor exposing (Floor)
import Model.Prototype exposing (Prototype)
import Model.Serialization exposing (..)
import Model.SearchResult exposing (SearchResult)
import Model.ColorPalette exposing (ColorPalette)


type alias Error = Http.Error


type alias Config =
  { apiRoot : String
  , accountServiceRoot : String
  , token : String
  }


-- createNewFloor : Task Error Int

saveEditingFloor : Config -> Floor -> ObjectsChange -> Task Error Int
saveEditingFloor config floor change =
  putJson
    decodeFloorVersion
    (config.apiRoot ++ "/1/floors/" ++ floor.id)
    (authorization config.token)
    (Http.string <| serializeFloor floor change)


publishEditingFloor : Config -> String -> Task Error Int
publishEditingFloor config id =
  putJson
    decodeFloorVersion
    (config.apiRoot ++ "/1/floors/" ++ id ++ "/public")
    (authorization config.token)
    (Http.string "")


getEditingFloor : Config -> String -> Task Error Floor
getEditingFloor config id =
  getFloorHelp config True id


getFloor : Config -> String -> Task Error Floor
getFloor config id =
  getFloorHelp config False id


getFloorOfVersion : Config -> String -> Int -> Task Error Floor
getFloorOfVersion config id version =
  let
    url =
      Http.url
        (config.apiRoot ++ "/1/floors/" ++ id ++ "/" ++ toString version)
        []
  in
    get decodeFloor url (authorization config.token)


getFloorHelp : Config -> Bool -> String -> Task Error Floor
getFloorHelp config withPrivate id =
  let
    url =
      Http.url
        (config.apiRoot ++ "/1/floors/" ++ id)
        (if withPrivate then [("all", "true")] else [])
  in
    getWithoutCache decodeFloor url (authorization config.token)


getFloorMaybe : Config -> String -> Task Error (Maybe Floor)
getFloorMaybe config id =
  getFloor config id
  `Task.andThen` (\floor -> Task.succeed (Just floor))
  `Task.onError` \e -> case e of
    Http.BadResponse 404 _ -> Task.succeed Nothing
    _ -> Task.fail e


getFloorsInfo : Config -> Bool -> Task Error (List FloorInfo)
getFloorsInfo config withPrivate =
  let
    url =
      Http.url
        (config.apiRoot ++ "/1/floors")
        (if withPrivate then [("all", "true")] else [])
  in
    getWithoutCache
      decodeFloorInfoList
      url
      (authorization config.token)


getPrototypes : Config -> Task Error (List Prototype)
getPrototypes config =
  getWithoutCache
    decodePrototypes
    (Http.url (config.apiRoot ++ "/1/prototypes") [])
    (authorization config.token)


savePrototypes : Config -> List Prototype -> Task Error ()
savePrototypes config prototypes =
  putJsonNoResponse
    (config.apiRoot ++ "/1/prototypes")
    (authorization config.token)
    (Http.string <| serializePrototypes prototypes)


getColors : Config -> Task Error ColorPalette
getColors config =
  getWithoutCache
    decodeColors
    (Http.url (config.apiRoot ++ "/1/colors") [])
    (authorization config.token)


getDiffSource : Config -> String -> Task Error (Floor, Maybe Floor)
getDiffSource config id =
  getEditingFloor config id
  `Task.andThen` \current -> getFloorMaybe config id
  `Task.andThen` \prev -> Task.succeed (current, prev)


getAuth : Config -> Task Error User
getAuth config =
  getWithoutCache
    decodeUser
    (config.apiRoot ++ "/1/self")
    (authorization config.token)


search : Config -> Bool -> String -> Task Error (List SearchResult)
search config withPrivate query =
  let
    url =
      Http.url
        (config.apiRoot ++ "/1/search/" ++ Http.uriEncode query)
        (if withPrivate then [("all", "true")] else [])
  in
    HttpUtil.get
      decodeSearchResults
      url
      (authorization config.token)


personCandidate : Config -> String -> Task Error (List Person)
personCandidate config name =
  if String.isEmpty name then
    Task.succeed []
  else
    getWithoutCache
      decodePersons
      (config.apiRoot ++ "/1/candidates/" ++ Http.uriEncode name)
      (authorization config.token)


saveEditingImage : Config -> Id -> File -> Task a ()
saveEditingImage config id file =
  HttpUtil.sendFile
    "PUT"
    (config.apiRoot ++ "/1/images/" ++ id)
    (authorization config.token)
    file


getPerson : Config -> Id -> Task Error Person
getPerson config id =
    HttpUtil.get
      decodePerson
      (config.apiRoot ++ "/1/people/" ++ id)
      (authorization config.token)


getPersonByUser : Config -> Id -> Task Error Person
getPersonByUser config id =
  let
    getUser =
      HttpUtil.get
        decodeUser
        (config.apiRoot ++ "/1/users/" ++ id)
        (authorization config.token)
  in
    getUser
    `Task.andThen` (\user -> case user of
        User.Admin person -> Task.succeed person
        User.General person -> Task.succeed person
        User.Guest -> Debug.crash ("user " ++ id ++ " has no person")
      )


login : String -> String -> String -> Task Error String
login accountServiceRoot id pass =
  postJson
    decodeAuthToken
    (accountServiceRoot ++ "/1/authentication")
    []
    (Http.string <| serializeLogin id pass)


goToLogin : Task a ()
goToLogin =
  HttpUtil.goTo "/login"


goToLogout : Task a ()
goToLogout =
  HttpUtil.goTo "/logout"


gotoTop : Task a ()
gotoTop =
  HttpUtil.goTo "/"
