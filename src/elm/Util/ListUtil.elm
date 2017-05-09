module Util.ListUtil exposing (..)


sepBy : Int -> List a -> List (List a)
sepBy count list =
    case List.drop count list of
        [] ->
            [ List.take count list ]

        cont ->
            List.take count list :: sepBy count cont


findBy : (a -> Bool) -> List a -> Maybe a
findBy f list =
    List.head (List.filter f list)


zipWithIndex : List a -> List ( a, Int )
zipWithIndex =
    zipWithIndexFrom 0


zipWithIndexFrom : Int -> List a -> List ( a, Int )
zipWithIndexFrom index list =
    case list of
        h :: t ->
            ( h, index ) :: zipWithIndexFrom (index + 1) t

        _ ->
            []


getAt : Int -> List a -> Maybe a
getAt index xs =
    if index < 0 then
        Nothing
    else
        List.head <| List.drop index xs


setAt : Int -> a -> List a -> List a
setAt index value list =
    case list of
        head :: tail ->
            if index == 0 then
                value :: tail
            else
                head :: setAt (index - 1) value tail

        [] ->
            list


deleteAt : Int -> List a -> List a
deleteAt index list =
    case list of
        head :: tail ->
            if index == 0 then
                tail
            else
                head :: deleteAt (index - 1) tail

        [] ->
            list
