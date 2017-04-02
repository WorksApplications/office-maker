module CoreType exposing (..)


import Json.Encode


type alias Position =
  { x : Int
  , y : Int
  }


type alias PositionFloat =
  { x : Float
  , y : Float
  }


type alias Size =
  { width : Int
  , height : Int
  }


type alias Id =
  String


type alias ObjectId =
  Id


type alias PersonId =
  Id


type alias FloorId =
  Id


type alias Json =
  Json.Encode.Value
