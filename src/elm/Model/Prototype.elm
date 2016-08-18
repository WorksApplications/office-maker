module Model.Prototype exposing (..)

type alias Id =
  String


type alias Prototype =
  { id : Id
  , name : String
  , backgroundColor : String
  , size : (Int, Int)
  }
