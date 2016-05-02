module Util.HttpUtil where

import Task exposing(..)
import Native.HttpUtil
import Util.File as File exposing(File(File))
import Http
import Json.Decode exposing (Decoder)

reload : Task a ()
reload =
  Native.HttpUtil.reload

goTo : String -> Task a ()
goTo =
  Native.HttpUtil.goTo

sendFile : String -> String -> File.File -> Task a ()
sendFile method url (File file) =
  Native.HttpUtil.sendFile method url file

sendJson : String -> Decoder value -> String -> Http.Body -> Task Http.Error value
sendJson verb decoder url body =
  let request =
    { verb = verb
    , headers =
        [("Content-Type", "application/json; charset=utf-8")]
    , url = url
    , body = body
    }
  in
    Http.fromJson decoder (Http.send Http.defaultSettings request)

postJson : Decoder value -> String -> Http.Body -> Task Http.Error value
postJson = sendJson "POST"

putJson : Decoder value -> String -> Http.Body -> Task Http.Error value
putJson = sendJson "PUT"
