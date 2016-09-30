module Model.Object exposing (..)

import Model.Person as Person

type alias Id = String

type Shape
  = Rectangle
  | Ellipse


type Object =
  Object
    { id : Id
    , rect : (Int, Int, Int, Int) -- (x, y, width, height)
    , backgroundColor : String
    , name : String
    , fontSize : Float
    , extension : ObjectExtension
    }


type ObjectExtension
  = Desk (Maybe Person.Id)
  | Label String Shape


isDesk : Object -> Bool
isDesk (Object object) =
  case object.extension of
    Desk _ ->
      True

    _ ->
      False


isLabel : Object -> Bool
isLabel (Object object) =
  case object.extension of
    Label _ _ ->
      True

    _ ->
      False


initDesk : Id -> (Int, Int, Int, Int) -> String -> String -> Float -> Maybe Person.Id -> Object
initDesk id rect backgroundColor name fontSize personId =
  Object
    { id = id
    , rect = rect
    , backgroundColor = backgroundColor
    , name = name
    , fontSize = fontSize
    , extension = Desk personId
    }


initLabel : Id -> (Int, Int, Int, Int) -> String -> String -> Float -> String -> Shape -> Object
initLabel id rect backgroundColor name fontSize color shape =
  Object
    { id = id
    , rect = rect
    , backgroundColor = backgroundColor
    , name = name
    , fontSize = fontSize
    , extension = Label color shape
    }


copy : Id -> (Int, Int) -> Object -> Object
copy newId pos object =
  (changeId newId << move pos) object


position : Object -> (Int, Int)
position (Object object) =
  case object.rect of
    (x, y, _, _) ->
      (x, y)


changeId : String -> Object -> Object
changeId id (Object object) =
  Object { object | id = id }


changeBackgroundColor : String -> Object -> Object
changeBackgroundColor backgroundColor (Object object) =
  Object { object | backgroundColor = backgroundColor }


changeColor : String -> Object -> Object
changeColor color (Object object) =
  case object.extension of
    Desk _ ->
      Object object

    Label _ shape ->
      Object { object | extension = Label color shape }


changeShape : Shape -> Object -> Object
changeShape shape (Object object) =
  case object.extension of
    Desk _ ->
      Object object

    Label color _ ->
      Object { object | extension = Label color shape }


changeName : String -> Object -> Object
changeName name (Object object) =
  Object { object | name = name }


changeSize : (Int, Int) -> Object -> Object
changeSize (w, h) (Object object) =
  case object.rect of
    (x, y, _, _) ->
      Object { object | rect = (x, y, w, h) }


move : (Int, Int) -> Object -> Object
move (x, y) (Object object) =
  case object.rect of
    (_, _, w, h) ->
      Object { object | rect = (x, y, w, h) }


rotate : Object -> Object
rotate (Object object) =
  case object.rect of
    (x, y, w, h) ->
      Object { object | rect = (x, y, h, w) }


setPerson : Maybe Person.Id -> Object -> Object
setPerson personId (Object object) =
  case object.extension of
    Desk _ ->
      Object { object | extension = Desk personId }

    _ ->
      Object object


changeFontSize : Float -> Object -> Object
changeFontSize fontSize (Object object) =
  Object { object | fontSize = fontSize }


idOf : Object -> Id
idOf (Object object) =
  object.id


nameOf : Object -> String
nameOf (Object object) =
  object.name


backgroundColorOf : Object -> String
backgroundColorOf (Object object) =
  object.backgroundColor


colorOf : Object -> String
colorOf (Object object) =
  case object.extension of
    Desk _ ->
      "#000"

    Label color _ ->
      color


defaultFontSize : Float
defaultFontSize = 16


fontSizeOf : Object -> Float
fontSizeOf (Object object) =
  object.fontSize


shapeOf : Object -> Shape
shapeOf (Object object) =
  case object.extension of
    Desk _ ->
      Rectangle

    Label _ shape ->
      shape


rect : Object -> (Int, Int, Int, Int)
rect (Object object) =
  object.rect


relatedPerson : Object -> Maybe Person.Id
relatedPerson (Object object) =
  case object.extension of
    Desk personId ->
      personId

    _ ->
      Nothing


backgroundColorEditable : Object -> Bool
backgroundColorEditable _ = True


colorEditable : Object -> Bool
colorEditable = isLabel


shapeEditable : Object -> Bool
shapeEditable = isLabel


fontSizeEditable : Object -> Bool
fontSizeEditable _ = True


--
