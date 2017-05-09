module Model.ObjectsOperation exposing (..)

import Model.Object as Object exposing (Object)
import CoreType exposing (..)


centerOf : Object -> PositionFloat
centerOf object =
    let
        { x, y } =
            Object.positionOf object

        { width, height } =
            Object.sizeOf object
    in
        PositionFloat (toFloat x + toFloat width / 2) (toFloat y + toFloat height / 2)


linked : ( Position, Size ) -> ( Position, Size ) -> Bool
linked ( pos1, size1 ) ( pos2, size2 ) =
    pos1.x
        <= pos2.x
        + size2.width
        && pos2.x
        <= pos1.x
        + size1.width
        && pos1.y
        <= pos2.y
        + size2.height
        && pos2.y
        <= pos1.y
        + size1.height


linkedByAnyOf : List Object -> Object -> Bool
linkedByAnyOf list newObject =
    let
        newRect =
            ( Object.positionOf newObject, Object.sizeOf newObject )
    in
        List.any
            (\object ->
                linked ( Object.positionOf object, Object.sizeOf object ) newRect
            )
            list


island : List Object -> List Object -> List Object
island current rest =
    let
        ( newObjects, rest_ ) =
            List.partition (linkedByAnyOf current) rest
    in
        if List.isEmpty newObjects then
            current ++ newObjects
        else
            island (current ++ newObjects) rest_


compareBy : Direction -> Object -> Object -> Order
compareBy direction from new =
    let
        center =
            centerOf from

        newCenter =
            centerOf new
    in
        if center.x == newCenter.x && center.y == newCenter.y then
            EQ
        else
            let
                greater =
                    case direction of
                        Up ->
                            (newCenter.x < center.x) || (newCenter.x == center.x && newCenter.y < center.y)

                        Down ->
                            (newCenter.x > center.x) || (newCenter.x == center.x && newCenter.y > center.y)

                        Left ->
                            (newCenter.y < center.y) || (newCenter.y == center.y && newCenter.x < center.x)

                        Right ->
                            (newCenter.y > center.y) || (newCenter.y == center.y && newCenter.x > center.x)
            in
                if greater then
                    GT
                else
                    LT


lessBy : Direction -> Object -> Object -> Bool
lessBy direction from new =
    compareBy direction from new == LT


greaterBy : Direction -> Object -> Object -> Bool
greaterBy direction from new =
    compareBy direction from new == GT


minimumBy : Direction -> List Object -> Maybe Object
minimumBy direction list =
    let
        f o1 memo =
            case memo of
                Just o ->
                    if lessBy direction o o1 then
                        Just o1
                    else
                        Just o

                Nothing ->
                    Just o1
    in
        List.foldl f Nothing list


{-| Defines if given object can be selected next.
-}
filterCandidate : Direction -> Object -> Object -> Bool
filterCandidate direction from new =
    greaterBy direction from new


{-| Returns the next object toward given direction.
-}
nearest : Direction -> Object -> List Object -> Maybe Object
nearest direction from list =
    let
        filtered =
            List.filter (filterCandidate direction from) list
    in
        if List.isEmpty filtered then
            minimumBy direction list
        else
            minimumBy direction filtered


withinRange : ( Object, Object ) -> List Object -> List Object
withinRange ( startObject, endObject ) list =
    let
        start =
            centerOf startObject

        end =
            centerOf endObject

        left =
            min start.x end.x

        right =
            max start.x end.x

        top =
            min start.y end.y

        bottom =
            max start.y end.y
    in
        withinRect ( left, top ) ( right, bottom ) list


withinRect : ( Float, Float ) -> ( Float, Float ) -> List Object -> List Object
withinRect ( left, top ) ( right, bottom ) list =
    List.filter (\object -> isInRect ( left, top, right, bottom ) (centerOf object)) list


isInRect : ( Float, Float, Float, Float ) -> PositionFloat -> Bool
isInRect ( left, top, right, bottom ) { x, y } =
    x
        >= left
        && x
        <= right
        && y
        >= top
        && y
        <= bottom


bounds : List Object -> Maybe ( Int, Int, Int, Int )
bounds list =
    case list of
        head :: tail ->
            let
                f o ( x, y, right, bottom ) =
                    ( min x (Object.left o)
                    , min y (Object.top o)
                    , max right (Object.right o)
                    , max bottom (Object.bottom o)
                    )
            in
                Just <| List.foldl f ( Object.left head, Object.top head, Object.right head, Object.bottom head ) tail

        [] ->
            Nothing


bound : Direction -> Object -> Int
bound direction object =
    case direction of
        Up ->
            Object.top object

        Down ->
            Object.bottom object

        Left ->
            Object.left object

        Right ->
            Object.right object


compareBoundBy : Direction -> Object -> Object -> Order
compareBoundBy direction o1 o2 =
    case direction of
        Up ->
            if Object.top o1 == Object.top o2 then
                EQ
            else if Object.top o1 < Object.top o2 then
                GT
            else
                LT

        Down ->
            if Object.bottom o1 == Object.bottom o2 then
                EQ
            else if Object.bottom o1 > Object.bottom o2 then
                GT
            else
                LT

        Left ->
            if Object.left o1 == Object.left o2 then
                EQ
            else if Object.left o1 < Object.left o2 then
                GT
            else
                LT

        Right ->
            if Object.right o1 == Object.right o2 then
                EQ
            else if Object.right o1 > Object.right o2 then
                GT
            else
                LT


minimumPartsOf : Direction -> List Object -> List Object
minimumPartsOf direction list =
    let
        f o memo =
            case memo of
                head :: _ ->
                    case compareBoundBy direction o head of
                        LT ->
                            [ o ]

                        EQ ->
                            o :: memo

                        GT ->
                            memo

                _ ->
                    [ o ]
    in
        List.foldl f [] list


maximumPartsOf : Direction -> List Object -> List Object
maximumPartsOf direction list =
    let
        f o memo =
            case memo of
                head :: _ ->
                    case compareBoundBy direction o head of
                        LT ->
                            memo

                        EQ ->
                            o :: memo

                        GT ->
                            [ o ]

                _ ->
                    [ o ]
    in
        List.foldl f [] list


restOfMinimumPartsOf : Direction -> List Object -> List Object
restOfMinimumPartsOf direction list =
    let
        minimumParts =
            minimumPartsOf direction list
    in
        List.filter (\o -> not (List.member o minimumParts)) list


restOfMaximumPartsOf : Direction -> List Object -> List Object
restOfMaximumPartsOf direction list =
    let
        maximumParts =
            maximumPartsOf direction list
    in
        List.filter (\o -> not (List.member o maximumParts)) list


expandOrShrinkToward : Direction -> Object -> List Object -> List Object -> List Object
expandOrShrinkToward direction primary current all =
    let
        left0 =
            Object.left primary

        top0 =
            Object.top primary

        right0 =
            Object.right primary

        bottom0 =
            Object.bottom primary

        ( left, top, right, bottom ) =
            Maybe.withDefault
                ( left0, top0, right0, bottom0 )
                (bounds current)

        isExpand =
            case direction of
                Up ->
                    bottom == bottom0 && top <= top0

                Down ->
                    top == top0 && bottom >= bottom0

                Left ->
                    right == right0 && left <= left0

                Right ->
                    left == left0 && right >= right0
    in
        if isExpand then
            let
                filter o1 =
                    case direction of
                        Up ->
                            Object.left o1 >= left && Object.right o1 <= right && Object.top o1 < top

                        Down ->
                            Object.left o1 >= left && Object.right o1 <= right && Object.bottom o1 > bottom

                        Left ->
                            Object.top o1 >= top && Object.bottom o1 <= bottom && Object.left o1 < left

                        Right ->
                            Object.top o1 >= top && Object.bottom o1 <= bottom && Object.right o1 > right

                filtered =
                    List.filter filter all
            in
                current ++ minimumPartsOf direction filtered
        else
            restOfMaximumPartsOf (opposite direction) current


pasteObjects : FloorId -> Position -> List ( Object, ObjectId ) -> List Object
pasteObjects floorId base copiedWithNewIds =
    let
        min =
            copiedWithNewIds
                |> List.map (\( object, newId ) -> Object.positionOf object)
                |> minBoundsOf

        newObjects =
            List.map
                (\( object, newId ) ->
                    let
                        { x, y } =
                            Object.positionOf object

                        pos =
                            Position (base.x + (x - min.x)) (base.y + (y - min.y))
                    in
                        object
                            |> Object.changePosition pos
                            |> Object.changeId newId
                            |> Object.changeFloorId floorId
                )
                copiedWithNewIds
    in
        newObjects


minBoundsOf : List Position -> Position
minBoundsOf positions =
    positions
        |> List.foldl
            (\{ x, y } min ->
                Position (Basics.min min.x x) (Basics.min min.y y)
            )
            (Position 99999 99999)


fitPositionToGrid : Int -> Position -> Position
fitPositionToGrid gridSize { x, y } =
    Position (fitToGrid gridSize x) (fitToGrid gridSize y)


fitSizeToGrid : Int -> Size -> Size
fitSizeToGrid gridSize size =
    Size (fitToGrid gridSize size.width) (fitToGrid gridSize size.height)


fitToGrid : Int -> Int -> Int
fitToGrid gridSize i =
    i // gridSize * gridSize


backgroundColorProperty : List Object -> Maybe String
backgroundColorProperty selectedObjects =
    collectSameProperty Object.backgroundColorOf selectedObjects


colorProperty : List Object -> Maybe String
colorProperty selectedObjects =
    collectSameProperty Object.colorOf selectedObjects


shapeProperty : List Object -> Maybe Object.Shape
shapeProperty selectedObjects =
    collectSameProperty Object.shapeOf selectedObjects


nameProperty : List Object -> Maybe String
nameProperty selectedObjects =
    collectSameProperty Object.nameOf selectedObjects


fontSizeProperty : List Object -> Maybe Float
fontSizeProperty selectedObjects =
    collectSameProperty Object.fontSizeOf selectedObjects



-- [red, green, green] -> Nothing
-- [blue, blue] -> Just blue
-- [] -> Nothing


collectSameProperty : (Object -> a) -> List Object -> Maybe a
collectSameProperty getProp selectedObjects =
    List.head selectedObjects
        |> Maybe.andThen
            (\object ->
                let
                    firstProp =
                        getProp object
                in
                    List.foldl
                        (\object maybeProp ->
                            let
                                prop =
                                    getProp object
                            in
                                maybeProp
                                    |> Maybe.andThen
                                        (\prop_ ->
                                            if prop == prop_ then
                                                Just prop
                                            else
                                                Nothing
                                        )
                        )
                        (Just firstProp)
                        selectedObjects
            )


flipObject : Size -> Object -> Object
flipObject floorSize object =
    let
        right =
            Object.right object

        bottom =
            Object.bottom object

        newLeft =
            floorSize.width - right

        newTop =
            floorSize.height - bottom
    in
        Object.changePosition (Position newLeft newTop) object



--
