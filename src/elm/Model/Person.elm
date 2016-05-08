module Model.Person exposing (..) -- where

type alias Id = String

type alias Person =
  { id : Id
  , name : String
  , org : String
  , image : Maybe String
  }
