module Model.Equipment exposing (..)

import Model.Person as Person

type alias Id = String

type Equipment =
  Desk Id (Int, Int, Int, Int) String String (Maybe Person.Id)-- id (x, y, width, height) color name


init : Id -> (Int, Int, Int, Int) -> String -> String -> Maybe Person.Id -> Equipment
init = Desk


copy : Id -> (Int, Int) -> Equipment -> Equipment
copy newId (x, y) equipment =
  case equipment of
    Desk _ (_, _, w, h) color name personId ->
      Desk newId (x, y, w, h) color name personId


position : Equipment -> (Int, Int)
position equipment =
  case equipment of
    Desk _ (x, y, w, h) color name personId -> (x, y)


changeColor : String -> Equipment -> Equipment
changeColor color (Desk id rect _ name personId) =
  Desk id rect color name personId


changeName : String -> Equipment -> Equipment
changeName name (Desk id rect color _ personId) =
  Desk id rect color name personId


changeSize : (Int, Int) -> Equipment -> Equipment
changeSize (w, h) (Desk id (x, y, _, _) color name personId) =
  Desk id (x, y, w, h) color name personId


idOf : Equipment -> Id
idOf (Desk id _ _ _ _) =
  id

nameOf : Equipment -> String
nameOf (Desk _ _ _ name _) =
  name

colorOf : Equipment -> String
colorOf (Desk _ _ color _ _) =
  color

move : (Int, Int) -> Equipment -> Equipment
move (newX, newY) (Desk id (x, y, width, height) color name personId) =
  Desk id (newX, newY, width, height) color name personId

rect : Equipment -> (Int, Int, Int, Int)
rect (Desk _ rect _ _ _) =
  rect


rotate : Equipment -> Equipment
rotate (Desk id (x, y, width, height) color name personId) =
  (Desk id (x, y, height, width) color name personId)


setPerson : Maybe Person.Id -> Equipment -> Equipment
setPerson personId (Desk id rect color name _) =
  (Desk id rect color name personId)


relatedPerson : Equipment -> Maybe Person.Id
relatedPerson (Desk _ _ _ _ personId) =
  personId


--
