module Util.HttpUtil exposing (..)

import Task exposing (..)
import Native.HttpUtil
import Util.File as File exposing (File(File))
import Http exposing (..)
import Json.Decode as Decode exposing (Decoder)
-- import Result exposing (Result(..))

reload : Task a ()
reload =
  Native.HttpUtil.reload


goTo : String -> Task a ()
goTo =
  Native.HttpUtil.goTo


sendFile : String -> String -> File.File -> Task a ()
sendFile method url (File file) =
  Native.HttpUtil.sendFile method url file


contentTypeJsonUtf8 : List (String, String)
contentTypeJsonUtf8 =
  [("Content-Type", "application/json; charset=utf-8")]


defaultSettingsWithCredentials : Http.Settings
defaultSettingsWithCredentials =
  let
    settings = Http.defaultSettings
  in
    { settings | withCredentials = True }


sendJson : String -> Decoder value -> String -> Http.Body -> Task Http.Error value
sendJson verb decoder url body =
  let request =
    { verb = verb
    , headers = contentTypeJsonUtf8
    , url = url
    , body = body
    }
  in
    Http.fromJson decoder (Http.send defaultSettingsWithCredentials request)


sendJsonNoResponse : String -> String -> Http.Body -> Task Http.Error ()
sendJsonNoResponse verb url body =
  let request =
    { verb = verb
    , headers = contentTypeJsonUtf8
    , url = url
    , body = body
    }
  in
    noResponse (Http.send defaultSettingsWithCredentials request)


getJsonWithoutCache : Decoder value -> String -> Task Http.Error value
getJsonWithoutCache decoder url =
  let request =
    { verb = "GET"
    , headers =
        contentTypeJsonUtf8 ++
        [ ("Pragma", "no-cache")
        , ("Cache-Control", "no-cache")
        , ("If-Modified-Since", "Thu, 01 Jun 1970 00:00:00 GMT")
        ]
    , url = url
    , body = Http.empty
    }
  in
    Http.fromJson decoder (Http.send defaultSettingsWithCredentials request)


postJson : Decoder value -> String -> Http.Body -> Task Http.Error value
postJson = sendJson "POST"


postJsonNoResponse : String -> Http.Body -> Task Http.Error ()
postJsonNoResponse = sendJsonNoResponse "POST"


putJson : Decoder value -> String -> Http.Body -> Task Http.Error value
putJson = sendJson "PUT"


putJsonNoResponse : String -> Http.Body -> Task Http.Error ()
putJsonNoResponse = sendJsonNoResponse "PUT"


patchJson : Decoder value -> String -> Http.Body -> Task Http.Error value
patchJson = sendJson "PATCH"


deleteJson : Decoder value -> String -> Http.Body -> Task Http.Error value
deleteJson = sendJson "DELETE"


deleteJsonNoResponse : String -> Http.Body -> Task Http.Error ()
deleteJsonNoResponse = sendJsonNoResponse "DELETE"


recover404With : a -> (Http.Error -> Task Http.Error a)
recover404With alt = \e ->
  case e of
    Http.BadResponse 404 _ ->
      Task.succeed alt
    _ -> Task.fail e


noResponse : Task RawError Response -> Task Error ()
noResponse response =
  fromText (always (Ok ())) response


fromText : (String -> Result String a) -> Task RawError Response -> Task Error a
fromText decoder response =
  let
    decode str =
      case decoder str of
        Ok v -> succeed v
        Err msg -> fail (UnexpectedPayload msg)
  in
    mapError promoteError response
      `andThen` handleResponse decode


fromJson : Decoder a -> Task RawError Response -> Task Error a
fromJson decoder response =
  fromText (Decode.decodeString decoder) response


handleResponse : (String -> Task Error a) -> Response -> Task Error a
handleResponse handle response =
  if 200 <= response.status && response.status < 300 then
    case response.value of
      Text str ->
          handle str

      _ ->
          fail (UnexpectedPayload "Response body is a blob, expecting a string.")
  else
      fail (BadResponse response.status response.statusText)



promoteError : RawError -> Error
promoteError rawError =
  case rawError of
    RawTimeout -> Timeout
    RawNetworkError -> NetworkError
