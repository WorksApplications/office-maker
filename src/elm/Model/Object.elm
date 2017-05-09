module Model.Object exposing (..)

import Time exposing (Time)
import CoreType exposing (..)


type alias FloorVersion =
    Int


type Shape
    = Rectangle
    | Ellipse


type Object
    = Object
        { id : ObjectId
        , floorId : FloorId
        , floorVersion : Maybe FloorVersion
        , position : Position
        , size : Size
        , backgroundColor : String
        , name : String
        , fontSize : Float
        , updateAt : Maybe Time
        , extension : ObjectExtension
        }


type alias LabelFields =
    { color : String
    , bold : Bool
    , url : String
    , shape : Shape
    }


type ObjectExtension
    = Desk (Maybe PersonId)
    | Label LabelFields


type ObjectPropertyChange
    = ChangeName String String
    | ChangeSize Size Size
    | ChangePosition Position Position
    | ChangeBackgroundColor String String
    | ChangeColor String String
    | ChangeFontSize Float Float
    | ChangeBold Bool Bool
    | ChangeUrl String String
    | ChangeShape Shape Shape
    | ChangePerson (Maybe PersonId) (Maybe PersonId)


modifyAll : List ObjectPropertyChange -> Object -> Object
modifyAll changes object =
    changes
        |> List.foldl modify object


modify : ObjectPropertyChange -> Object -> Object
modify change object =
    case change of
        ChangeName new old ->
            changeName new object

        ChangeSize new old ->
            changeSize new object

        ChangePosition new old ->
            changePosition new object

        ChangeBackgroundColor new old ->
            changeBackgroundColor new object

        ChangeColor new old ->
            changeColor new object

        ChangeFontSize new old ->
            changeFontSize new object

        ChangeBold new old ->
            changeBold new object

        ChangeUrl new old ->
            changeUrl new object

        ChangeShape new old ->
            changeShape new object

        ChangePerson new old ->
            setPerson new object


copyUpdateAt : Object -> Object -> Object
copyUpdateAt (Object src) (Object dest) =
    Object { dest | updateAt = src.updateAt }


setUpdateAt : Time -> Object -> Object
setUpdateAt updateAt (Object object) =
    Object { object | updateAt = Just updateAt }


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
        Label _ ->
            True

        _ ->
            False


initDesk : ObjectId -> FloorId -> Maybe FloorVersion -> Position -> Size -> String -> String -> Float -> Maybe Time -> Maybe PersonId -> Object
initDesk id floorId floorVersion position size backgroundColor name fontSize updateAt personId =
    Object
        { id = id
        , floorId = floorId
        , floorVersion = floorVersion
        , position = position
        , size = size
        , backgroundColor = backgroundColor
        , name = name
        , fontSize = fontSize
        , updateAt = updateAt
        , extension = Desk personId
        }


initLabel : ObjectId -> FloorId -> Maybe FloorVersion -> Position -> Size -> String -> String -> Float -> Maybe Time -> LabelFields -> Object
initLabel id floorId floorVersion position size backgroundColor name fontSize updateAt extension =
    Object
        { id = id
        , floorId = floorId
        , floorVersion = floorVersion
        , position = position
        , size = size
        , backgroundColor = backgroundColor
        , name = name
        , fontSize = fontSize
        , updateAt = updateAt
        , extension = Label extension
        }


changeId : ObjectId -> Object -> Object
changeId id (Object object) =
    Object { object | id = id }


changeFloorId : FloorId -> Object -> Object
changeFloorId floorId (Object object) =
    Object { object | floorId = floorId }


changeBackgroundColor : String -> Object -> Object
changeBackgroundColor backgroundColor (Object object) =
    Object { object | backgroundColor = backgroundColor }


changeColor : String -> Object -> Object
changeColor color (Object object) =
    case object.extension of
        Desk _ ->
            Object object

        Label additionalFields ->
            Object { object | extension = Label { additionalFields | color = color } }


changeName : String -> Object -> Object
changeName name (Object object) =
    Object { object | name = name }


changeSize : Size -> Object -> Object
changeSize size (Object object) =
    Object { object | size = size }


changePosition : Position -> Object -> Object
changePosition position (Object object) =
    Object { object | position = position }


rotate : Object -> Object
rotate (Object object) =
    Object { object | size = Size object.size.height object.size.width }


setPerson : Maybe PersonId -> Object -> Object
setPerson personId ((Object object) as obj) =
    case object.extension of
        Desk _ ->
            Object { object | extension = Desk personId }

        _ ->
            obj


changeFontSize : Float -> Object -> Object
changeFontSize fontSize (Object object) =
    Object { object | fontSize = fontSize }


changeBold : Bool -> Object -> Object
changeBold bold ((Object object) as obj) =
    case object.extension of
        Desk _ ->
            obj

        Label fields ->
            Object { object | extension = Label { fields | bold = bold } }


changeUrl : String -> Object -> Object
changeUrl url ((Object object) as obj) =
    case object.extension of
        Desk _ ->
            obj

        Label fields ->
            Object { object | extension = Label { fields | url = url } }


changeShape : Shape -> Object -> Object
changeShape shape ((Object object) as obj) =
    case object.extension of
        Desk _ ->
            obj

        Label additionalFields ->
            Object { object | extension = Label { additionalFields | shape = shape } }


idOf : Object -> ObjectId
idOf (Object object) =
    object.id


floorIdOf : Object -> FloorId
floorIdOf (Object object) =
    object.floorId


floorVersionOf : Object -> Maybe FloorVersion
floorVersionOf (Object object) =
    object.floorVersion


updateAtOf : Object -> Maybe Time
updateAtOf (Object object) =
    object.updateAt


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

        Label { color } ->
            color


defaultFontSize : Float
defaultFontSize =
    20


fontSizeOf : Object -> Float
fontSizeOf (Object object) =
    object.fontSize


isBold : Object -> Bool
isBold (Object object) =
    case object.extension of
        Desk _ ->
            False

        Label { bold } ->
            bold


urlOf : Object -> String
urlOf (Object object) =
    case object.extension of
        Desk _ ->
            ""

        Label { url } ->
            url


shapeOf : Object -> Shape
shapeOf (Object object) =
    case object.extension of
        Desk _ ->
            Rectangle

        Label { shape } ->
            shape


sizeOf : Object -> Size
sizeOf (Object object) =
    object.size


positionOf : Object -> Position
positionOf (Object object) =
    object.position


left : Object -> Int
left object =
    .x <| positionOf object


top : Object -> Int
top object =
    .y <| positionOf object


right : Object -> Int
right (Object object) =
    object.position.x + object.size.width


bottom : Object -> Int
bottom (Object object) =
    object.position.y + object.size.height


relatedPerson : Object -> Maybe PersonId
relatedPerson (Object object) =
    case object.extension of
        Desk personId ->
            personId

        _ ->
            Nothing


backgroundColorEditable : Object -> Bool
backgroundColorEditable _ =
    True


colorEditable : Object -> Bool
colorEditable =
    isLabel


shapeEditable : Object -> Bool
shapeEditable =
    isLabel


fontSizeEditable : Object -> Bool
fontSizeEditable _ =
    True


urlEditable : Object -> Bool
urlEditable =
    isLabel



--
