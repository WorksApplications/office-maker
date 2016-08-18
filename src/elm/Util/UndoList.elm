module Util.UndoList exposing (UndoList, init, undo, redo, new)


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
undo model =
  case model.past of
    x :: xs ->
      { model |
        past = xs
      , present = x
      , future = model.present :: model.future
      }

    _ ->
      model


redo : UndoList a -> UndoList a
redo model =
  case model.future of
    x :: xs ->
      { model |
        past = model.present :: model.past
      , present = x
      , future = xs
      }

    _ ->
      model


new : a -> UndoList a -> UndoList a
new a model =
  { model |
    past = model.present :: model.past
  , present = a
  , future = []
  }


--
