module Model.Floor exposing (..)

import Dict exposing (Dict)
import Regex
import Date exposing (Date)
import Model.Object as Object exposing (Object)
import Model.ObjectsOperation as ObjectsOperation
import Model.ObjectsChange as ObjectsChange exposing (DetailedObjectsChange, ObjectModification)
import CoreType exposing (..)


type alias FloorBase =
    { id : FloorId
    , version : Int
    , temporary : Bool
    , name : String
    , ord : Int
    }


type alias Detailed a =
    { a
        | width : Int
        , height : Int
        , realSize : Maybe ( Int, Int )
        , image : Maybe String
        , flipImage : Bool
        , update : Maybe { by : PersonId, at : Date }
        , objects : Dict ObjectId Object
    }


type alias Floor =
    Detailed FloorBase


init : FloorId -> Floor
init id =
    { id = id
    , version = 0
    , name = "New Floor"
    , ord = 0
    , objects = Dict.empty
    , width = 800
    , height = 600
    , realSize = Nothing
    , temporary = False
    , image = Nothing
    , flipImage = False
    , update = Nothing
    }


empty : Floor
empty =
    init ""


baseOf : Floor -> FloorBase
baseOf { id, version, temporary, name, ord } =
    FloorBase id version temporary name ord


initWithOrder : FloorId -> Int -> Floor
initWithOrder id ord =
    let
        floor =
            init id
    in
        { floor
            | ord = ord
        }


changeName : String -> Floor -> Floor
changeName name floor =
    { floor | name = name }


changeOrd : Int -> Floor -> Floor
changeOrd ord floor =
    { floor | ord = ord }


setImage : String -> Int -> Int -> Floor -> Floor
setImage url width height floor =
    { floor
        | width = width
        , height = height
        , image = Just url
    }


changeRealSize : ( Int, Int ) -> Floor -> Floor
changeRealSize ( width, height ) floor =
    { floor
        | realSize = Just ( width, height )
    }



{- 10cm -> 8px -}


realToPixel : Int -> Int
realToPixel real =
    Basics.floor (toFloat real * 80)


pixelToReal : Int -> Int
pixelToReal pixel =
    Basics.floor (toFloat pixel / 80)


size : Floor -> Size
size floor =
    case floor.realSize of
        Just ( w, h ) ->
            Size (realToPixel w) (realToPixel h)

        Nothing ->
            Size floor.width floor.height


name : Floor -> String
name floor =
    floor.name


width : Floor -> Int
width floor =
    size floor |> .width


height : Floor -> Int
height floor =
    size floor |> .height



-- TODO confusing...


realSize : Floor -> ( Int, Int )
realSize floor =
    case floor.realSize of
        Just ( w, h ) ->
            ( w, h )

        Nothing ->
            ( pixelToReal floor.width, pixelToReal floor.height )


src : Floor -> Maybe String
src floor =
    case floor.image of
        Just src ->
            Just ("./images/floors/" ++ src)

        Nothing ->
            Nothing


changeId : FloorId -> Floor -> Floor
changeId id floor =
    { floor | id = id }


copy : FloorId -> Bool -> Floor -> Floor
copy id temporary floor =
    { floor
        | id = id
        , version = 0
        , name =
            if temporary then
                "Temporary from " ++ floor.name
            else
                "Copy of " ++ floor.name
        , update = Nothing
        , objects = Dict.empty
        , temporary = temporary
    }


flip : Floor -> Floor
flip floor =
    { floor
        | flipImage = not floor.flipImage
    }
        |> fullyChangeObjects (ObjectsOperation.flipObject <| size floor)



-- OBJECT OPERATIONS


move : List ObjectId -> Int -> ( Int, Int ) -> Floor -> Floor
move ids gridSize ( dx, dy ) floor =
    partiallyChangeObjects
        (moveObjects gridSize ( dx, dy ))
        ids
        floor


moveObjects : Int -> ( Int, Int ) -> Object -> Object
moveObjects gridSize ( dx, dy ) object =
    let
        pos =
            Object.positionOf object

        new =
            ObjectsOperation.fitPositionToGrid
                gridSize
                (Position (pos.x + dx) (pos.y + dy))
    in
        Object.changePosition new object


paste : List ( Object, ObjectId ) -> Position -> Floor -> Floor
paste copiedWithNewIds base floor =
    addObjects
        (ObjectsOperation.pasteObjects floor.id base copiedWithNewIds)
        floor


rotateObjects : List ObjectId -> Floor -> Floor
rotateObjects ids floor =
    partiallyChangeObjects (Object.rotate) ids floor


changeObjectColor : List ObjectId -> String -> Floor -> Floor
changeObjectColor ids color floor =
    partiallyChangeObjects (Object.changeColor color) ids floor


changeObjectBackgroundColor : List ObjectId -> String -> Floor -> Floor
changeObjectBackgroundColor ids color floor =
    partiallyChangeObjects (Object.changeBackgroundColor color) ids floor


changeObjectShape : List ObjectId -> Object.Shape -> Floor -> Floor
changeObjectShape ids shape floor =
    partiallyChangeObjects (Object.changeShape shape) ids floor


changeObjectName : List ObjectId -> String -> Floor -> Floor
changeObjectName ids name floor =
    partiallyChangeObjects (Object.changeName name) ids floor


changeObjectFontSize : List ObjectId -> Float -> Floor -> Floor
changeObjectFontSize ids fontSize floor =
    partiallyChangeObjects (Object.changeFontSize fontSize) ids floor


changeObjectUrl : List ObjectId -> String -> Floor -> Floor
changeObjectUrl ids url floor =
    partiallyChangeObjects (Object.changeUrl url) ids floor


changeObjectsByChanges : DetailedObjectsChange -> Floor -> Floor
changeObjectsByChanges change floor =
    let
        separated =
            ObjectsChange.separate change
    in
        floor
            |> addObjects separated.added
            |> modifyObjects separated.modified
            |> removeObjects (List.map Object.idOf separated.deleted)


toFirstNameOnly : List ObjectId -> Floor -> Floor
toFirstNameOnly ids floor =
    let
        change name =
            case String.words name of
                [] ->
                    ""

                x :: _ ->
                    x

        f object =
            Object.changeName (change (Object.nameOf object)) object
    in
        partiallyChangeObjects f ids floor


fullyChangeObjects : (Object -> Object) -> Floor -> Floor
fullyChangeObjects f floor =
    { floor
        | objects =
            Dict.map (\_ object -> f object) floor.objects
    }


partiallyChangeObjects : (Object -> Object) -> List ObjectId -> Floor -> Floor
partiallyChangeObjects f ids floor =
    { floor
        | objects =
            ids
                |> List.foldl
                    (\objectId dict -> Dict.update objectId (Maybe.map f) dict)
                    floor.objects
    }


removeSpaces : List ObjectId -> Floor -> Floor
removeSpaces ids floor =
    let
        change name =
            (Regex.replace Regex.All (Regex.regex "[ \x0D\n\x3000]") (\_ -> "")) name

        f object =
            Object.changeName (change <| Object.nameOf object) object
    in
        partiallyChangeObjects f ids floor


resizeObject : ObjectId -> Size -> Floor -> Floor
resizeObject id size floor =
    partiallyChangeObjects (Object.changeSize size) [ id ] floor


setPerson : ObjectId -> PersonId -> Floor -> Floor
setPerson objectId personId floor =
    setPeople [ ( objectId, personId ) ] floor


unsetPerson : ObjectId -> Floor -> Floor
unsetPerson objectId floor =
    partiallyChangeObjects (Object.setPerson Nothing) [ objectId ] floor


setPeople : List ( ObjectId, PersonId ) -> Floor -> Floor
setPeople pairs floor =
    let
        f ( objectId, personId ) dict =
            dict
                |> Dict.update objectId (Maybe.map (Object.setPerson (Just personId)))

        newObjects =
            List.foldl f (floor.objects) pairs
    in
        { floor | objects = newObjects }


objects : Floor -> List Object
objects floor =
    Dict.values floor.objects


getObject : ObjectId -> Floor -> Maybe Object
getObject objectId floor =
    Dict.get objectId floor.objects


getObjects : List ObjectId -> Floor -> List Object
getObjects ids floor =
    ids
        |> List.filterMap (\id -> getObject id floor)


setObjects : List Object -> Floor -> Floor
setObjects objects floor =
    { floor
        | objects =
            objectsDictFromList floor.id objects
    }


addObjects : List Object -> Floor -> Floor
addObjects objects floor =
    { floor
        | objects =
            objects
                |> filterObjectsInFloor floor.id
                |> List.foldl (\object -> Dict.insert (Object.idOf object) object) floor.objects
    }


modifyObjects : List ObjectModification -> Floor -> Floor
modifyObjects list floor =
    { floor
        | objects =
            list
                |> List.foldl
                    (\mod dict ->
                        Dict.update
                            (Object.idOf mod.new)
                            (Maybe.map (Object.copyUpdateAt mod.old << Object.modifyAll mod.changes))
                            dict
                    )
                    floor.objects
    }


removeObjects : List ObjectId -> Floor -> Floor
removeObjects objectIds floor =
    { floor
        | objects =
            List.foldl Dict.remove floor.objects objectIds
    }


objectsDictFromList : FloorId -> List Object -> Dict ObjectId Object
objectsDictFromList floorId objects =
    objects
        |> filterObjectsInFloor floorId
        |> List.map (\object -> ( Object.idOf object, object ))
        |> Dict.fromList


filterObjectsInFloor : FloorId -> List Object -> List Object
filterObjectsInFloor floorId objects =
    objects
        |> List.filter (\object -> Object.floorIdOf object == floorId)
