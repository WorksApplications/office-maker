module Model.Prototype exposing (..)

type alias Id =
  String


type alias Prototype =
  (Id, String, String, (Int, Int)) -- id, color, name, size
