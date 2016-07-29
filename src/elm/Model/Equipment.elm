module Model.Equipment exposing (..)

import Model.Person as Person

type alias Id = String

type Shape
  = Rectangle
  | Ellipse


type Equipment
  = Desk Id (Int, Int, Int, Int) String String (Maybe Person.Id) -- id (x, y, width, height) background-color name personId
  | Label Id (Int, Int, Int, Int) String String Float String Shape -- id (x, y, width, height) background-color name fontSize color shape


isDesk : Equipment -> Bool
isDesk equipment =
  case equipment of
    Desk _ _ _ _ _ ->
      True
    _ ->
      False


isLabel : Equipment -> Bool
isLabel equipment =
  case equipment of
    Label _ _ _ _ _ _ _ ->
      True
    _ ->
      False


initDesk : Id -> (Int, Int, Int, Int) -> String -> String -> Maybe Person.Id -> Equipment
initDesk =
  Desk


initLabel : Id -> (Int, Int, Int, Int) -> String -> String -> Float -> String -> Shape -> Equipment
initLabel =
  Label


copy : Id -> (Int, Int) -> Equipment -> Equipment
copy newId pos equipment =
  (changeId newId << move pos) equipment


position : Equipment -> (Int, Int)
position equipment =
  case equipment of
    Desk _ (x, y, w, h) bgColor name personId ->
      (x, y)
    Label _ (x, y, w, h) bgColor name fontSize color shape ->
      (x, y)


changeId : String -> Equipment -> Equipment
changeId id e =
  case e of
    Desk _ rect color name personId ->
      Desk id rect color name personId
    Label _ rect bgColor name fontSize color shape ->
      Label id rect bgColor name fontSize color shape


changeBackgroundColor : String -> Equipment -> Equipment
changeBackgroundColor bgColor e =
  case e of
    Desk id rect _ name personId ->
      Desk id rect bgColor name personId
    Label id rect _ name fontSize color shape ->
      Label id rect bgColor name fontSize color shape


changeColor : String -> Equipment -> Equipment
changeColor color e =
  case e of
    Desk id rect bgColor name personId ->
      e
    Label id rect bgColor name fontSize _ shape ->
      Label id rect bgColor name fontSize color shape


changeShape : Shape -> Equipment -> Equipment
changeShape shape e =
  case e of
    Desk id rect bgColor name personId ->
      e
    Label id rect bgColor name fontSize color _ ->
      Label id rect bgColor name fontSize color shape


changeName : String -> Equipment -> Equipment
changeName name e =
  case e of
    Desk id rect bgColor _ personId ->
      Desk id rect bgColor name personId
    Label id rect bgColor _ fontSize color shape ->
      Label id rect bgColor name fontSize color shape


changeSize : (Int, Int) -> Equipment -> Equipment
changeSize (w, h) e =
  case e of
    Desk id (x, y, _, _) bgColor name personId ->
      Desk id (x, y, w, h) bgColor name personId
    Label id (x, y, _, _) bgColor name fontSize color shape ->
      Label id (x, y, w, h) bgColor name fontSize color shape


move : (Int, Int) -> Equipment -> Equipment
move (newX, newY) e =
  case e of
    Desk id (_, _, width, height) bgColor name personId ->
      Desk id (newX, newY, width, height) bgColor name personId
    Label id (_, _, width, height) bgColor name fontSize color shape ->
      Label id (newX, newY, width, height) bgColor name fontSize color shape


rotate : Equipment -> Equipment
rotate e =
  let
    (x, y, w, h) = rect e
  in
    changeSize (h, w) e


setPerson : Maybe Person.Id -> Equipment -> Equipment
setPerson personId e =
  case e of
    Desk id rect bgColor name _ ->
      Desk id rect bgColor name personId
    _ ->
      e


idOf : Equipment -> Id
idOf e =
  case e of
    Desk id _ _ _ _ ->
      id
    Label id _ _ _ _ _ _ ->
      id


nameOf : Equipment -> String
nameOf e =
  case e of
    Desk _ _ _ name _ ->
      name
    Label _ _ _ name _ _ _ ->
      name


backgroundColorOf : Equipment -> String
backgroundColorOf e =
  case e of
    Desk _ _ bgColor _ _ ->
      bgColor
    Label _ _ bgColor _ _ _ _ ->
      bgColor


colorOf : Equipment -> String
colorOf e =
  case e of
    Desk _ _ _ _ _ ->
      "#000"
    Label _ _ _ _ _ color _ ->
      color


defaultFontSize : Float
defaultFontSize = 12


fontSizeOf : Equipment -> Float
fontSizeOf e =
  case e of
    Desk _ _ _ _ _ ->
      defaultFontSize
    Label _ _ _ _ fontSize _ _ ->
      fontSize


shapeOf : Equipment -> Shape
shapeOf e =
  case e of
    Desk _ _ _ _ _ ->
      Rectangle
    Label _ _ _ _ _ _ shape ->
      shape


rect : Equipment -> (Int, Int, Int, Int)
rect e =
  case e of
    Desk _ rect _ _ _ ->
      rect
    Label _ rect _ _ _ _ _ ->
      rect


relatedPerson : Equipment -> Maybe Person.Id
relatedPerson e =
  case e of
    Desk _ _ _ _ personId ->
      personId
    _ ->
      Nothing


backgroundColorEditable : Equipment -> Bool
backgroundColorEditable e =
  case e of
    Desk _ _ _ _ _ ->
      True
    Label _ _ _ _ _ _ _ ->
      True


colorEditable : Equipment -> Bool
colorEditable e =
  case e of
    Desk _ _ _ _ _ ->
      False
    Label _ _ _ _ _ _ _ ->
      True


shapeEditable : Equipment -> Bool
shapeEditable e =
  case e of
    Desk _ _ _ _ _ ->
      False
    Label _ _ _ _ _ _ _ ->
      True


fontSizeEditable : Equipment -> Bool
fontSizeEditable e =
  case e of
    Desk _ _ _ _ _ ->
      False
    Label _ _ _ _ _ _ _ ->
      True
--
