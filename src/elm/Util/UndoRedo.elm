module Util.UndoRedo exposing (Model, init, undo, redo, commit)


type alias Model a commit =
  { past : List a
  , present : a
  , future : List a
  , update : commit -> a -> a
  }


init : { data : a, update : commit -> a -> a } -> Model a commit
init { data, update } =
  { past = []
  , present = data
  , future = []
  , update = update
  }


undo : Model a commit -> Model a commit
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


redo : Model a commit -> Model a commit
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


commit : commit -> Model a commit -> Model a commit
commit commit model =
  { model |
    past = model.present :: model.past
  , present = model.update commit model.present
  , future = []
  }


-- dataAt : Int -> Model a commit -> a
-- dataAt cursor model =
--   replay
--     model.update
--     (List.reverse (commitsUntil cursor model.commits))
--     model.original


-- canUndo : Model a commit -> Bool
-- canUndo model =
--   not (List.isEmpty (commitsUntil model.cursor model.commits))
--
-- canRedo : Model a commit -> Bool
-- canRedo model =
--   model.cursor > 0

-- commitsUntil : Int -> List commit -> List commit
-- commitsUntil cursor commits =
--   List.drop cursor commits
--
-- replay : (commit -> a -> a) -> List commit -> a -> a
-- replay update commitsAsc original =
--   List.foldl update original commitsAsc

-- debug : Model a commit -> String
