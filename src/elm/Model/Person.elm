module Model.Person exposing (..)


type alias Id =
    String


type alias Person =
    { id : Id
    , name : String
    , post : String
    , mail : Maybe String
    , tel1 : Maybe String
    , tel2 : Maybe String
    , image : Maybe String
    }
