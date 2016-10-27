module Model.Prototype exposing (..)

import Model.Object exposing (Shape)

type alias Id =
  String


type alias Prototype =
  { id : Id
  , name : String
  , color : String
  , backgroundColor : String
  , size : (Int, Int)
  , fontSize : Float
  , shape : Shape
  , personId : Maybe String
  }
