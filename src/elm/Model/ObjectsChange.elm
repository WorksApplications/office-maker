module Model.ObjectsChange exposing (..)

import Dict exposing (Dict)
import Model.Object as Object exposing (..)
import CoreType exposing (..)


type alias ObjectModification =
    { new : Object, old : Object, changes : List ObjectPropertyChange }


type ObjectChange a
    = Added Object
    | Modified a
    | Deleted Object


type alias ObjectsChange_ a =
    Dict ObjectId (ObjectChange a)


type alias ObjectsChange =
    ObjectsChange_ Object


type alias DetailedObjectsChange =
    ObjectsChange_ ObjectModification


added : List Object -> ObjectsChange_ a
added objects =
    objects
        |> List.map (\object -> ( Object.idOf object, Added object ))
        |> Dict.fromList


modified : List ( ObjectId, a ) -> ObjectsChange_ a
modified idRelatedList =
    idRelatedList
        |> List.map (\( id, a ) -> ( id, Modified a ))
        |> Dict.fromList


empty : ObjectsChange
empty =
    Dict.empty


isEmpty : ObjectsChange_ a -> Bool
isEmpty change =
    Dict.isEmpty change


merge : Dict ObjectId Object -> ObjectsChange -> ObjectsChange -> ObjectsChange
merge currentObjects new old =
    Dict.merge
        (\id new dict -> insertToMergedDict currentObjects id new dict)
        (\id new old dict ->
            case ( new, old ) of
                ( Deleted _, Added _ ) ->
                    dict

                ( Modified object, Added _ ) ->
                    insertToMergedDict currentObjects id (Added object) dict

                _ ->
                    insertToMergedDict currentObjects id new dict
        )
        (\id old dict -> insertToMergedDict currentObjects id old dict)
        new
        old
        Dict.empty


insertToMergedDict : Dict ObjectId Object -> ObjectId -> ObjectChange Object -> ObjectsChange -> ObjectsChange
insertToMergedDict currentObjects id value dict =
    currentObjects
        |> Dict.get id
        |> Maybe.map
            (\currentObject ->
                Dict.insert id (copyCurrentUpdateAtToObjects currentObject value) dict
            )
        |> Maybe.withDefault (Dict.insert id value dict)



-- current object does not exist if deleted


copyCurrentUpdateAtToObjects : Object -> ObjectChange Object -> ObjectChange Object
copyCurrentUpdateAtToObjects currentObject modification =
    case modification of
        Added object ->
            Added (Object.copyUpdateAt currentObject object)

        Modified object ->
            Modified (Object.copyUpdateAt currentObject object)

        Deleted object ->
            Deleted (Object.copyUpdateAt currentObject object)


fromList : List ( ObjectId, ObjectChange a ) -> ObjectsChange_ a
fromList list =
    Dict.fromList list


toList : ObjectsChange_ a -> List (ObjectChange a)
toList change =
    List.map Tuple.second (Dict.toList change)


separate : ObjectsChange_ a -> { added : List Object, modified : List a, deleted : List Object }
separate change =
    let
        ( added, modified, deleted ) =
            Dict.foldl
                (\_ value ( added, modified, deleted ) ->
                    case value of
                        Added object ->
                            ( object :: added, modified, deleted )

                        Modified a ->
                            ( added, a :: modified, deleted )

                        Deleted object ->
                            ( added, modified, object :: deleted )
                )
                ( [], [], [] )
                change
    in
        { added = added
        , modified = modified
        , deleted = deleted
        }


simplify : DetailedObjectsChange -> ObjectsChange
simplify change =
    change
        |> Dict.map
            (\id value ->
                case value of
                    Added object ->
                        Added object

                    Modified mod ->
                        Modified mod.new

                    Deleted object ->
                        Deleted object
            )
