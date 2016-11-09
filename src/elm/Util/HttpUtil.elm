module Util.HttpUtil exposing (..)

import Task exposing (..)
import Native.HttpUtil
import Util.File as File exposing (File(File))
import Http exposing (..)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode

reload : Task a ()
reload =
  Native.HttpUtil.reload


goTo : String -> Task a ()
goTo =
  Native.HttpUtil.goTo


encodeHeaders : List (String, String) -> Encode.Value
encodeHeaders headers =
  Encode.list (List.map (\(k, v) -> Encode.list [Encode.string k, Encode.string v]) headers)


sendFile : String -> String -> List (String, String) -> File.File -> Task a ()
sendFile method url headers (File file) =
  Native.HttpUtil.sendFile method url (encodeHeaders headers) file


contentTypeJsonUtf8 : List (String, String)
contentTypeJsonUtf8 =
  [("Content-Type", "application/json; charset=utf-8")]


authorization : String -> List (String, String)
authorization s =
  [("Authorization", s)]


defaultSettingsWithCredentials : Http.Settings
defaultSettingsWithCredentials =
  let
    settings = Http.defaultSettings
  in
    { settings | withCredentials = True }


sendJson : String -> Decoder value -> String -> List (String, String) -> Http.Body -> Task Http.Error value
sendJson verb decoder url headers body =
  let request =
    { verb = verb
    , headers = contentTypeJsonUtf8 ++ headers
    , url = url
    , body = body
    }
  in
    Http.fromJson decoder (Http.send defaultSettingsWithCredentials request)


sendJsonNoResponse : String -> String -> List (String, String) -> Http.Body -> Task Http.Error ()
sendJsonNoResponse verb url headers body =
  let request =
    { verb = verb
    , headers = contentTypeJsonUtf8 ++ headers
    , url = url
    , body = body
    }
  in
    noResponse (Http.send defaultSettingsWithCredentials request)


sendJsonTextResponse : String -> String -> List (String, String) -> Http.Body -> Task Http.Error String
sendJsonTextResponse verb url headers body =
  let request =
    { verb = verb
    , headers = contentTypeJsonUtf8 ++ headers
    , url = url
    , body = body
    }
  in
    textResponse (Http.send defaultSettingsWithCredentials request)


get : Decoder value -> String -> List (String, String) -> Task Http.Error value
get decoder url headers =
  let
    request =
      { verb = "GET"
      , headers =
          contentTypeJsonUtf8 ++ headers
      , url = url
      , body = Http.empty
      }
  in
    Http.fromJson decoder (Http.send defaultSettingsWithCredentials request)


getWithoutCache : Decoder value -> String -> List (String, String) -> Task Http.Error value
getWithoutCache decoder url headers =
  let
    headers' =
      [ ("Pragma", "no-cache")
      , ("Cache-Control", "no-cache")
      , ("If-Modified-Since", "Thu, 01 Jun 1970 00:00:00 GMT")
      ] ++ headers
  in
    get decoder url headers'


postJson : Decoder value -> String -> List (String, String) -> Http.Body -> Task Http.Error value
postJson = sendJson "POST"


postJsonNoResponse : String -> List (String, String) -> Http.Body -> Task Http.Error ()
postJsonNoResponse = sendJsonNoResponse "POST"


postJsonTextResponse : String -> List (String, String) -> Http.Body -> Task Http.Error String
postJsonTextResponse = sendJsonTextResponse "POST"


putJson : Decoder value -> String -> List (String, String) -> Http.Body -> Task Http.Error value
putJson = sendJson "PUT"


putJsonNoResponse : String -> List (String, String) -> Http.Body -> Task Http.Error ()
putJsonNoResponse = sendJsonNoResponse "PUT"


patchJson : Decoder value -> String -> List (String, String) -> Http.Body -> Task Http.Error value
patchJson = sendJson "PATCH"


patchJsonNoResponse : String -> List (String, String) -> Http.Body -> Task Http.Error ()
patchJsonNoResponse = sendJsonNoResponse "PATCH"


deleteJson : Decoder value -> String -> List (String, String) -> Http.Body -> Task Http.Error value
deleteJson = sendJson "DELETE"


deleteJsonNoResponse : String -> List (String, String) -> Http.Body -> Task Http.Error ()
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


textResponse : Task RawError Response -> Task Error String
textResponse response =
  fromText Ok response


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
