module Model.Equipment exposing (..)

import Model.Person as Person

type alias Id = String

type Equipment
  = Desk Id (Int, Int, Int, Int) String String (Maybe Person.Id) -- id (x, y, width, height) color name personId
  | Label Id (Int, Int, Int, Int) String String Int -- id (x, y, width, height) color name fontSize


initDesk : Id -> (Int, Int, Int, Int) -> String -> String -> Maybe Person.Id -> Equipment
initDesk =
  Desk


initLabel : Id -> (Int, Int, Int, Int) -> String -> String -> Int -> Equipment
initLabel =
  Label


copy : Id -> (Int, Int) -> Equipment -> Equipment
copy newId pos equipment =
  (changeId newId << move pos) equipment


position : Equipment -> (Int, Int)
position equipment =
  case equipment of
    Desk _ (x, y, w, h) color name personId ->
      (x, y)
    Label _ (x, y, w, h) color name fontSize ->
      (x, y)


changeId : String -> Equipment -> Equipment
changeId id e =
  case e of
    Desk _ rect color name personId ->
      Desk id rect color name personId
    Label _ rect color name fontSize ->
      Label id rect color name fontSize


changeColor : String -> Equipment -> Equipment
changeColor color e =
  case e of
    Desk id rect _ name personId ->
      Desk id rect color name personId
    Label id rect _ name fontSize ->
      Label id rect color name fontSize


changeName : String -> Equipment -> Equipment
changeName name e =
  case e of
    Desk id rect color _ personId ->
      Desk id rect color name personId
    Label id rect color _ fontSize ->
      Label id rect color name fontSize


changeSize : (Int, Int) -> Equipment -> Equipment
changeSize (w, h) e =
  case e of
    Desk id (x, y, _, _) color name personId ->
      Desk id (x, y, w, h) color name personId
    Label id (x, y, _, _) color name fontSize ->
      Label id (x, y, w, h) color name fontSize


move : (Int, Int) -> Equipment -> Equipment
move (newX, newY) e =
  case e of
    Desk id (_, _, width, height) color name personId ->
      Desk id (newX, newY, width, height) color name personId
    Label id (_, _, width, height) color name fontSize ->
      Label id (newX, newY, width, height) color name fontSize


rotate : Equipment -> Equipment
rotate e =
  let
    (x, y, w, h) = rect e
  in
    changeSize (h, w) e


setPerson : Maybe Person.Id -> Equipment -> Equipment
setPerson personId e =
  case e of
    Desk id rect color name _ ->
      Desk id rect color name personId
    _ ->
      e


idOf : Equipment -> Id
idOf e =
  case e of
    Desk id _ _ _ _ ->
      id
    Label id _ _ _ _ ->
      id


nameOf : Equipment -> String
nameOf e =
  case e of
    Desk _ _ _ name _ ->
      name
    Label _ _ _ name _ ->
      name


colorOf : Equipment -> String
colorOf e =
  case e of
    Desk _ _ color _ _ ->
      color
    Label _ _ color _ _ ->
      color


rect : Equipment -> (Int, Int, Int, Int)
rect e =
  case e of
    Desk _ rect _ _ _ ->
      rect
    Label _ rect _ _ _ ->
      rect


relatedPerson : Equipment -> Maybe Person.Id
relatedPerson e =
  case e of
    Desk _ _ _ _ personId ->
      personId
    _ ->
      Nothing


--
