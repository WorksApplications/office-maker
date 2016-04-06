module Equipments (Id, Equipment(..)) where

type alias Id = String

type Equipment =
  Desk Id (Int, Int, Int, Int) String String -- id (x, y, width, height) color
