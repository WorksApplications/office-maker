module Model.Prototypes exposing (..)

import Model.Prototype exposing (Prototype)
import Model.ObjectsOperation as ObjectsOperation
import Util.ListUtil exposing (..)
import CoreType exposing (..)


type alias PositionedPrototype =
    ( Prototype, Position )


type alias Prototypes =
    { data : List Prototype
    , selected : Int
    }


gridSize : Int
gridSize =
    8



--TODO


init : List Prototype -> Prototypes
init data =
    { data = data
    , selected = 0 -- index
    }


type Msg
    = SelectPrev
    | SelectNext


prev : Msg
prev =
    SelectPrev


next : Msg
next =
    SelectNext


update : Msg -> Prototypes -> Prototypes
update msg model =
    case msg of
        SelectPrev ->
            { model
                | selected = max 0 (model.selected - 1) -- fail safe
            }

        SelectNext ->
            { model
                | selected = min (List.length model.data - 1) (model.selected + 1) -- fail safe
            }


register : Prototype -> Prototypes -> Prototypes
register prototype model =
    let
        newPrototypes =
            model.data ++ [ prototype ]
    in
        { model
            | data = newPrototypes
            , selected = List.length newPrototypes - 1
        }


selectedPrototype : Prototypes -> Prototype
selectedPrototype model =
    findPrototypeByIndex model.selected model.data


findPrototypeByIndex : Int -> List Prototype -> Prototype
findPrototypeByIndex index list =
    case getAt index list of
        Just prototype ->
            prototype

        Nothing ->
            case List.head list of
                Just prototype ->
                    prototype

                Nothing ->
                    Debug.crash "no prototypes found"


prototypes : Prototypes -> List ( Prototype, Bool )
prototypes model =
    model.data
        |> List.indexedMap
            (\index prototype ->
                ( prototype, model.selected == index )
            )


stampIndices : Bool -> Size -> Position -> Position -> ( List Int, List Int )
stampIndices horizontal deskSize pos1 pos2 =
    let
        ( amountX, amountY ) =
            if horizontal then
                let
                    amountX =
                        (abs (pos2.x - pos1.x) + deskSize.width // 2) // deskSize.width

                    amountY =
                        if abs (pos2.y - pos1.y) > (deskSize.height // 2) then
                            1
                        else
                            0
                in
                    ( amountX, amountY )
            else
                let
                    amountX =
                        if abs (pos2.x - pos1.x) > (deskSize.width // 2) then
                            1
                        else
                            0

                    amountY =
                        (abs (pos2.y - pos1.y) + deskSize.height // 2) // deskSize.height
                in
                    ( amountX, amountY )
    in
        ( List.map
            (\i ->
                if pos2.x > pos1.x then
                    i
                else
                    -i
            )
            (List.range 0 amountX)
        , List.map
            (\i ->
                if pos2.y > pos1.y then
                    i
                else
                    -i
            )
            (List.range 0 amountY)
        )


generateAllCandidatePosition : Size -> Position -> ( List Int, List Int ) -> List Position
generateAllCandidatePosition deskSize centerPos ( indicesX, indicesY ) =
    let
        lefts =
            List.map (\index -> centerPos.x + deskSize.width * index) indicesX

        tops =
            List.map (\index -> centerPos.y + deskSize.height * index) indicesY
    in
        List.concatMap (\left -> List.map (\top -> Position left top) tops) lefts


positionedPrototypesOnDragging : Int -> Prototype -> Position -> Position -> List PositionedPrototype
positionedPrototypesOnDragging gridSize prototype xy1 xy2 =
    -- imagePos
    let
        x1 =
            xy1.x

        y1 =
            xy1.y

        x2 =
            xy2.x

        y2 =
            xy2.y

        deskSize =
            ( prototype.width, prototype.height )

        flip ( w, h ) =
            ( h, w )

        horizontal =
            abs (x2 - x1) > abs (y2 - y1)

        ( deskWidth, deskHeight ) =
            if horizontal then
                flip deskSize
            else
                deskSize

        ( indicesX, indicesY ) =
            stampIndices horizontal (Size deskWidth deskHeight) xy1 xy2

        center =
            ObjectsOperation.fitPositionToGrid
                gridSize
                (Position (x1 - Tuple.first deskSize // 2) (y1 - Tuple.second deskSize // 2))

        all =
            generateAllCandidatePosition
                (Size deskWidth deskHeight)
                center
                ( indicesX, indicesY )

        prototype_ =
            { prototype
                | width = deskWidth
                , height = deskHeight
            }
    in
        List.map ((,) prototype_) all
