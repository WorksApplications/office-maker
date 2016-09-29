module Model.Person exposing (..)

type alias Id = String

type alias Person =
  { id : Id
  , name : String
  , post : String
  , mail : Maybe String
  , tel : Maybe String
  , image : Maybe String
  }
