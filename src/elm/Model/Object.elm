module Model.Object exposing (..)

import Model.Person as Person

type alias Id = String

type Shape
  = Rectangle
  | Ellipse


type Object
  = Desk Id (Int, Int, Int, Int) String String (Maybe Person.Id) -- id (x, y, width, height) background-color name personId
  | Label Id (Int, Int, Int, Int) String String Float String Shape -- id (x, y, width, height) background-color name fontSize color shape


isDesk : Object -> Bool
isDesk object =
  case object of
    Desk _ _ _ _ _ ->
      True
    _ ->
      False


isLabel : Object -> Bool
isLabel object =
  case object of
    Label _ _ _ _ _ _ _ ->
      True
    _ ->
      False


initDesk : Id -> (Int, Int, Int, Int) -> String -> String -> Maybe Person.Id -> Object
initDesk =
  Desk


initLabel : Id -> (Int, Int, Int, Int) -> String -> String -> Float -> String -> Shape -> Object
initLabel =
  Label


copy : Id -> (Int, Int) -> Object -> Object
copy newId pos object =
  (changeId newId << move pos) object


position : Object -> (Int, Int)
position object =
  case object of
    Desk _ (x, y, w, h) bgColor name personId ->
      (x, y)
    Label _ (x, y, w, h) bgColor name fontSize color shape ->
      (x, y)


changeId : String -> Object -> Object
changeId id e =
  case e of
    Desk _ rect color name personId ->
      Desk id rect color name personId
    Label _ rect bgColor name fontSize color shape ->
      Label id rect bgColor name fontSize color shape


changeBackgroundColor : String -> Object -> Object
changeBackgroundColor bgColor e =
  case e of
    Desk id rect _ name personId ->
      Desk id rect bgColor name personId
    Label id rect _ name fontSize color shape ->
      Label id rect bgColor name fontSize color shape


changeColor : String -> Object -> Object
changeColor color e =
  case e of
    Desk id rect bgColor name personId ->
      e
    Label id rect bgColor name fontSize _ shape ->
      Label id rect bgColor name fontSize color shape


changeShape : Shape -> Object -> Object
changeShape shape e =
  case e of
    Desk id rect bgColor name personId ->
      e
    Label id rect bgColor name fontSize color _ ->
      Label id rect bgColor name fontSize color shape


changeName : String -> Object -> Object
changeName name e =
  case e of
    Desk id rect bgColor _ personId ->
      Desk id rect bgColor name personId
    Label id rect bgColor _ fontSize color shape ->
      Label id rect bgColor name fontSize color shape


changeSize : (Int, Int) -> Object -> Object
changeSize (w, h) e =
  case e of
    Desk id (x, y, _, _) bgColor name personId ->
      Desk id (x, y, w, h) bgColor name personId
    Label id (x, y, _, _) bgColor name fontSize color shape ->
      Label id (x, y, w, h) bgColor name fontSize color shape


move : (Int, Int) -> Object -> Object
move (newX, newY) e =
  case e of
    Desk id (_, _, width, height) bgColor name personId ->
      Desk id (newX, newY, width, height) bgColor name personId
    Label id (_, _, width, height) bgColor name fontSize color shape ->
      Label id (newX, newY, width, height) bgColor name fontSize color shape


rotate : Object -> Object
rotate e =
  let
    (x, y, w, h) = rect e
  in
    changeSize (h, w) e


setPerson : Maybe Person.Id -> Object -> Object
setPerson personId e =
  case e of
    Desk id rect bgColor name _ ->
      Desk id rect bgColor name personId
    _ ->
      e


changeFontSize : Float -> Object -> Object
changeFontSize fontSize e =
  case e of
    Desk id rect bgColor name personId ->
      Desk id rect bgColor name personId

    Label id rect bgColor name _ color shape ->
      Label id rect bgColor name fontSize color shape


idOf : Object -> Id
idOf e =
  case e of
    Desk id _ _ _ _ ->
      id
    Label id _ _ _ _ _ _ ->
      id


nameOf : Object -> String
nameOf e =
  case e of
    Desk _ _ _ name _ ->
      name
    Label _ _ _ name _ _ _ ->
      name


backgroundColorOf : Object -> String
backgroundColorOf e =
  case e of
    Desk _ _ bgColor _ _ ->
      bgColor
    Label _ _ bgColor _ _ _ _ ->
      bgColor


colorOf : Object -> String
colorOf e =
  case e of
    Desk _ _ _ _ _ ->
      "#000"
    Label _ _ _ _ _ color _ ->
      color


defaultFontSize : Float
defaultFontSize = 12


fontSizeOf : Object -> Float
fontSizeOf e =
  case e of
    Desk _ _ _ _ _ ->
      defaultFontSize
    Label _ _ _ _ fontSize _ _ ->
      fontSize


shapeOf : Object -> Shape
shapeOf e =
  case e of
    Desk _ _ _ _ _ ->
      Rectangle
    Label _ _ _ _ _ _ shape ->
      shape


rect : Object -> (Int, Int, Int, Int)
rect e =
  case e of
    Desk _ rect _ _ _ ->
      rect
    Label _ rect _ _ _ _ _ ->
      rect


relatedPerson : Object -> Maybe Person.Id
relatedPerson e =
  case e of
    Desk _ _ _ _ personId ->
      personId
    _ ->
      Nothing


backgroundColorEditable : Object -> Bool
backgroundColorEditable e =
  case e of
    Desk _ _ _ _ _ ->
      True
    Label _ _ _ _ _ _ _ ->
      True


colorEditable : Object -> Bool
colorEditable e =
  case e of
    Desk _ _ _ _ _ ->
      False
    Label _ _ _ _ _ _ _ ->
      True


shapeEditable : Object -> Bool
shapeEditable e =
  case e of
    Desk _ _ _ _ _ ->
      False
    Label _ _ _ _ _ _ _ ->
      True


fontSizeEditable : Object -> Bool
fontSizeEditable e =
  case e of
    Desk _ _ _ _ _ ->
      True
    Label _ _ _ _ _ _ _ ->
      True
--
