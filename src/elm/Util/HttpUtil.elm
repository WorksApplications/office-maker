module Util.HttpUtil where

import Task exposing(..)
import Native.HttpUtil
import Util.HtmlUtil as HtmlUtil exposing(FileList(FileList))

putFile : String -> HtmlUtil.FileList -> Task a ()
putFile url (FileList fileList) =
  Native.HttpUtil.putFile url fileList
