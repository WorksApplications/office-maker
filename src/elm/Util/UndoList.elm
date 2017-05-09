module Util.UndoList exposing (UndoList, init, undo, undoReplace, redo, redoReplace, new)


type alias UndoList a =
    { past : List a
    , present : a
    , future : List a
    }


init : a -> UndoList a
init data =
    { past = []
    , present = data
    , future = []
    }


undo : UndoList a -> UndoList a
undo undoList =
    case undoList.past of
        x :: xs ->
            { undoList
                | past = xs
                , present = x
                , future = undoList.present :: undoList.future
            }

        _ ->
            undoList


undoReplace : b -> (a -> a -> ( a, b )) -> UndoList a -> ( UndoList a, b )
undoReplace default f undoList =
    case undoList.past of
        x :: xs ->
            let
                ( newPresent, b ) =
                    f x undoList.present
            in
                ( { undoList
                    | past = xs
                    , present = newPresent
                    , future = undoList.present :: undoList.future
                  }
                , b
                )

        _ ->
            ( undoList, default )


redo : UndoList a -> UndoList a
redo undoList =
    case undoList.future of
        x :: xs ->
            { undoList
                | past = undoList.present :: undoList.past
                , present = x
                , future = xs
            }

        _ ->
            undoList


redoReplace : b -> (a -> a -> ( a, b )) -> UndoList a -> ( UndoList a, b )
redoReplace default f undoList =
    case undoList.future of
        x :: xs ->
            let
                ( newPresent, b ) =
                    f x undoList.present
            in
                ( { undoList
                    | past = undoList.present :: undoList.past
                    , present = newPresent
                    , future = xs
                  }
                , b
                )

        _ ->
            ( undoList, default )


new : a -> UndoList a -> UndoList a
new a undoList =
    { undoList
        | past = undoList.present :: undoList.past
        , present = a
        , future = []
    }



--
