module Model.FloorDiff exposing (..)

import Dict exposing (Dict)
import CoreType exposing (..)
import Model.Object as Object exposing (..)
import Model.Floor as Floor exposing (Floor)
import Model.ObjectsChange as ObjectsChange exposing (..)


type alias Options msg =
    { onClose : msg
    , onConfirm : msg
    , noOp : msg
    }


type alias PropChanges =
    List ( String, String, String )


diff : Floor -> Maybe Floor -> ( PropChanges, DetailedObjectsChange )
diff new old =
    ( diffPropertyChanges new old
    , diffObjects new.objects (Maybe.withDefault Dict.empty (Maybe.map .objects old))
    )


diffPropertyChanges : Floor -> Maybe Floor -> List ( String, String, String )
diffPropertyChanges current prev =
    case prev of
        Just prev ->
            propertyChangesHelp current prev

        -- FIXME completely wrong
        Nothing ->
            (if Floor.name current /= "" then
                [ ( "Name", Floor.name current, "" ) ]
             else
                []
            )
                ++ (case current.realSize of
                        Just ( w2, h2 ) ->
                            [ ( "Size", "(" ++ toString w2 ++ ", " ++ toString h2 ++ ")", "" ) ]

                        Nothing ->
                            []
                   )


propertyChangesHelp : Floor -> Floor -> List ( String, String, String )
propertyChangesHelp current prev =
    let
        nameChange =
            if Floor.name current == Floor.name prev then
                []
            else
                [ ( "Name", Floor.name current, Floor.name prev ) ]

        ordChange =
            if current.ord == prev.ord then
                []
            else
                [ ( "Order", toString current.ord, toString prev.ord ) ]

        sizeChange =
            if current.realSize == prev.realSize then
                []
            else
                case ( current.realSize, prev.realSize ) of
                    ( Just ( w1, h1 ), Just ( w2, h2 ) ) ->
                        [ ( "Size", "(" ++ toString w1 ++ ", " ++ toString h1 ++ ")", "(" ++ toString w2 ++ ", " ++ toString h2 ++ ")" ) ]

                    ( Just ( w1, h1 ), Nothing ) ->
                        [ ( "Size", "(" ++ toString w1 ++ ", " ++ toString h1 ++ ")", "" ) ]

                    ( Nothing, Just ( w2, h2 ) ) ->
                        [ ( "Size", "", "(" ++ toString w2 ++ ", " ++ toString h2 ++ ")" ) ]

                    _ ->
                        []

        -- should not happen
        imageChange =
            if current.image /= prev.image then
                [ ( "Image", Maybe.withDefault "" current.image, Maybe.withDefault "" prev.image ) ]
            else
                []

        flipImageChange =
            if current.flipImage /= prev.flipImage then
                [ ( "FlipImage", toString current.flipImage, toString prev.flipImage ) ]
            else
                []
    in
        nameChange ++ ordChange ++ sizeChange ++ imageChange ++ flipImageChange


diffObjects : Dict ObjectId Object -> Dict ObjectId Object -> DetailedObjectsChange
diffObjects newObjects oldObjects =
    Dict.merge
        (\id new dict -> Dict.insert id (ObjectsChange.Added new) dict)
        (\id new old dict ->
            case diffObjectProperty new old of
                [] ->
                    dict

                list ->
                    Dict.insert id (ObjectsChange.Modified { new = Object.copyUpdateAt old new, old = old, changes = list }) dict
        )
        (\id old dict -> Dict.insert id (ObjectsChange.Deleted old) dict)
        newObjects
        oldObjects
        Dict.empty


diffObjectProperty : Object -> Object -> List ObjectPropertyChange
diffObjectProperty new old =
    List.filterMap
        identity
        [ objectPropertyChange ChangeName Object.nameOf new old
        , objectPropertyChange ChangeSize Object.sizeOf new old
        , objectPropertyChange ChangePosition Object.positionOf new old
        , objectPropertyChange ChangeBackgroundColor Object.backgroundColorOf new old
        , objectPropertyChange ChangeColor Object.colorOf new old
        , objectPropertyChange ChangeFontSize Object.fontSizeOf new old
        , objectPropertyChange ChangeBold Object.isBold new old
        , objectPropertyChange ChangeUrl Object.urlOf new old
        , objectPropertyChange ChangeShape Object.shapeOf new old
        , objectPropertyChange ChangePerson Object.relatedPerson new old
        ]


objectPropertyChange : (a -> a -> b) -> (Object -> a) -> Object -> Object -> Maybe b
objectPropertyChange f toProperty new old =
    let
        newProp =
            toProperty new

        oldProp =
            toProperty old
    in
        if newProp /= oldProp then
            Just (f newProp oldProp)
        else
            Nothing



--
