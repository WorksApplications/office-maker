module UndoRedo (Model, init, undo, redo, commit, canUndo, canRedo, data) where

type alias Model a commit =
  { cursor : Int
  , original : a
  , commits : List commit
  , update : commit -> a -> a
  , cursorDataCache : a
  }

init : { data : a, update : commit -> a -> a } -> Model a commit
init { data, update } =
  { cursor = 0
  , original = data
  , commits = []
  , update = update
  , cursorDataCache = data
  }

undo : Model a commit -> Model a commit
undo model =
  if canUndo model then
    updateByCursorShift (model.cursor + 1) model
  else model

redo : Model a commit -> Model a commit
redo model =
  if canRedo model then
    updateByCursorShift (model.cursor - 1) model
  else model

commit : Model a commit -> commit -> Model a commit
commit model commit =
  let
    model' =
      { model |
        commits = commit :: (List.drop model.cursor model.commits)
      }
  in
    updateByCursorShift 0 model'

updateByCursorShift : Int -> Model a commit -> Model a commit
updateByCursorShift cursor model =
  { model |
    cursor = cursor
  , cursorDataCache = dataAt cursor model
  }

data : Model a commit -> a
data model =
  model.cursorDataCache

dataAt : Int -> Model a commit -> a
dataAt cursor model =
  replay
    model.update
    (List.reverse (commitsUntil cursor model.commits))
    model.original

canUndo : Model a commit -> Bool
canUndo model =
  not (List.isEmpty (commitsUntil model.cursor model.commits))

canRedo : Model a commit -> Bool
canRedo model =
  model.cursor > 0

commitsUntil : Int -> List commit -> List commit
commitsUntil cursor commits =
  List.drop cursor commits

replay : (commit -> a -> a) -> List commit -> a -> a
replay update commitsAsc original =
  List.foldl update original commitsAsc

-- debug : Model a commit -> String
