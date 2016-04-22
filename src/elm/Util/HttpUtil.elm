module Util.HttpUtil where

import Task exposing(..)
import Native.HttpUtil
import Util.File as File exposing(File(File))

sendFile : String -> String -> File.File -> Task a ()
sendFile method url (File file) =
  Native.HttpUtil.sendFile method url file
