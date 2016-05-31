module Model.API exposing (
      getAuth
    , search
    , saveEditingFloor
    , publishEditingFloor
    , getEditingFloor
    , getFloor
    , getDraftFloor
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
    , getColors
    , getPrototypes
    , Error
  ) -- where

import String
import Http
import Task exposing (Task)

import Util.HttpUtil as HttpUtil exposing (..)
import Util.File exposing (File)

import Model.Floor as Floor
import Model.User as User exposing (User)
import Model.Person exposing (Person)
import Model.Equipments as Equipments exposing (..)
import Model.Floor as Floor exposing (ImageSource(..))
import Model.Prototypes exposing (Prototype)
import Model.Serialization exposing (..)
import Model.SearchResult exposing (SearchResult)

type alias Floor = Floor.Model
type alias Error = Http.Error

saveEditingFloor : Floor -> Task Error ()
saveEditingFloor floor =
    putJson
      noResponse
      ("/api/v1/floor/" ++ Maybe.withDefault "draft" floor.id ++ "/edit")
      (Http.string <| serializeFloor floor)

publishEditingFloor : Floor -> Task Error ()
publishEditingFloor floor =
    postJson
      noResponse
      ("/api/v1/floor/" ++ Maybe.withDefault "draft" floor.id)
      (Http.string <| serializeFloor floor)

getEditingFloor : Maybe String -> Task Error Floor
getEditingFloor id =
    getJsonWithoutCache
      decodeFloor
      ("/api/v1/floor/" ++ Maybe.withDefault "draft" id ++ "/edit")

getFloorsInfo : Bool -> Task Error (List Floor)
getFloorsInfo withPrivate =
  let
    url =
      Http.url
        "/api/v1/floors"
        (if withPrivate then [("all", "true")] else [])
  in
    getJsonWithoutCache
      decodeFloors
      url

getPrototypes : Task Error (List Prototype)
getPrototypes =
    getJsonWithoutCache
      decodePrototypes
      (Http.url "/api/v1/prototypes" [])

getColors : Task Error (List String)
getColors =
    getJsonWithoutCache
      decodeColors
      (Http.url "/api/v1/colors" [])

-- getSettings : Task Error (List Prototype, List String)
-- getSettings =
--   getPrototypes
--   `Task.andThen` \prototypes -> getColors
--   `Task.andThen` \colors -> Task.succeed (prototypes, colors)

getFloor : Maybe String -> Task Error Floor
getFloor id =
    getJsonWithoutCache
      decodeFloor
      ("/api/v1/floor/" ++ Maybe.withDefault "draft" id)

getDraftFloor : Task Error (Maybe Floor)
getDraftFloor =
  getFloorMaybe Nothing


getFloorMaybe : Maybe String -> Task Error (Maybe Floor)
getFloorMaybe id =
  getFloor id
  `Task.andThen` (\floor -> Task.succeed (Just floor))
  `Task.onError` \e -> case e of
    Http.BadResponse 404 _ -> Task.succeed Nothing
    _ -> Task.fail e

getDiffSource : Maybe String -> Task Error (Floor, Maybe Floor)
getDiffSource id =
  getEditingFloor id
  `Task.andThen` \current -> getFloorMaybe id
  `Task.andThen` \prev -> Task.succeed (current, prev)

getAuth : Task Error User
getAuth =
    Http.get
      decodeUser
      ("/api/v1/auth")

search : Bool -> String -> Task Error (List SearchResult)
search withPrivate query =
  let
    url =
      Http.url
        ("/api/v1/search/" ++ Http.uriEncode query)
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
      decodePersons <| -- Debug.log "url" <|
      ("/api/v1/candidate/" ++ Http.uriEncode name)

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
      noResponse
      ("/api/v1/login")
      (Http.string <| serializeLogin id pass)

logout : Task Error ()
logout =
    postJson
      noResponse
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
