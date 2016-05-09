module Model.Person exposing (..) -- where

type alias Id = String

type alias Person =
  { id : Id
  , name : String
  , org : String
  -- , mail : Maybe String
  -- , tel : Maybe String
  , image : Maybe String
  }
