module Equipments (Id, Equipment(..), copy, position) where

type alias Id = String

type Equipment =
  Desk Id (Int, Int, Int, Int) String String -- id (x, y, width, height) color name

copy : Id -> (Int, Int) -> Equipment -> Equipment
copy newId (x, y) equipment =
  case equipment of
    Desk _ (_, _, w, h) color name ->
      Desk newId (x, y, w, h) color name

position : Equipment -> (Int, Int)
position equipment =
  case equipment of
    Desk _ (x, y, w, h) color name -> (x, y)
