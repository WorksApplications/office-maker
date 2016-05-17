module Model.Errors exposing (..) -- where

import Util.HtmlUtil as HtmlUtil
import Util.File as File

import Model.API as API exposing (..)

type GlobalError =
    APIError API.Error
  | FileError File.Error
  | HtmlError HtmlUtil.Error
  | Success String
  | NoError
