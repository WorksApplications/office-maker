module Model.Errors exposing (..)

import Dom
import Util.File as File
import API.API as API exposing (..)


type GlobalError
    = APIError API.Error
    | FileError File.Error
    | HtmlError Dom.Error
    | PasteError String
    | Success String
    | NoError
