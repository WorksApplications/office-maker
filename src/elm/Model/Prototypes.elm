module Model.Prototypes exposing (..) -- where

import Util.ListUtil exposing (..)
-- import Equipments exposing (..)
import Model.EquipmentsOperation as EquipmentsOperation exposing (..)

type alias PrototypeId =
  String

type alias Prototype =
  (PrototypeId, String, String, (Int, Int)) -- id color, name, size

type alias StampCandidate =
  (Prototype, (Int, Int))

type alias Model =
  { data : List Prototype
  , selected : Int
  }

gridSize : Int
gridSize = 8 --TODO

init : List Prototype -> Model
init data =
  { data = data
  , selected = 0 -- index
  }

type Msg =
    SelectPrev
  | SelectNext

prev : Msg
prev = SelectPrev

next : Msg
next = SelectNext

update : Msg -> Model -> Model
update action model =
  case action of
    SelectPrev ->
      { model |
        selected = max 0 (model.selected - 1) -- fail safe
      }
    SelectNext ->
      { model |
        selected = min (List.length model.data - 1) (model.selected + 1) -- fail safe
      }

register : Prototype -> Model -> Model
register prototype model =
  let
    newPrototypes = model.data ++ [prototype]
  in
    { model |
      data = newPrototypes
    , selected = List.length newPrototypes - 1
    }

selectedPrototype : Model -> Prototype
selectedPrototype model =
  findPrototypeByIndex model.selected model.data

findPrototypeByIndex : Int -> List Prototype -> Prototype
findPrototypeByIndex index list =
  case getAt index list of
    Just prototype ->
      prototype
    Nothing ->
      case List.head list of
        Just prototype -> prototype
        Nothing -> Debug.crash "no prototypes found"


prototypes : Model -> List (Prototype, Bool)
prototypes model =
  List.indexedMap (\index prototype ->
      (prototype, model.selected == index)
    ) model.data


stampIndices : Bool -> (Int, Int) -> (Int, Int) -> (Int, Int) -> (List Int, List Int)
stampIndices horizontal (deskWidth, deskHeight) (x1', y1') (x2', y2') =
  let
    (amountX, amountY) =
      if horizontal then
        let
          amountX = (abs (x2' - x1') + deskWidth // 2) // deskWidth
          amountY = if abs (y2' - y1') > (deskHeight // 2) then 1 else 0
        in
         (amountX, amountY)
      else
        let
          amountX = if abs (x2' - x1') > (deskWidth // 2) then 1 else 0
          amountY = (abs (y2' - y1') + deskHeight // 2) // deskHeight
        in
          (amountX, amountY)
  in
    ( List.map (\i -> if x2' > x1' then i else -i) [0..amountX]
    , List.map (\i -> if y2' > y1' then i else -i) [0..amountY] )


generateAllCandidatePosition : (Int, Int) -> (Int, Int) -> (List Int, List Int) -> List (Int, Int)
generateAllCandidatePosition (deskWidth, deskHeight) (centerLeft, centerTop) (indicesX, indicesY) =
  let
    lefts =
      List.map (\index -> centerLeft + deskWidth * index) indicesX
    tops =
      List.map (\index -> centerTop + deskHeight * index) indicesY
  in
    List.concatMap (\left -> List.map (\top -> (left, top)) tops) lefts

stampCandidatesOnDragging : Int -> Prototype -> (Int, Int) -> (Int, Int) -> List StampCandidate
stampCandidatesOnDragging gridSize prototype (x1, y1) (x2, y2) = -- imagePos
  let
    (prototypeId, color, name, deskSize) = prototype
    flip (w, h) = (h, w)
    horizontal = abs (x2 - x1) > abs (y2 - y1)
    (deskWidth, deskHeight) = if horizontal then flip deskSize else deskSize
    (indicesX, indicesY) =
      stampIndices horizontal (deskWidth, deskHeight) (x1, y1) (x2, y2)
    (centerLeft, centerTop) =
      fitToGrid gridSize (x1 - fst deskSize // 2, y1 - snd deskSize // 2)
    all =
      generateAllCandidatePosition
        (deskWidth, deskHeight)
        (centerLeft, centerTop)
        (indicesX, indicesY)
  in
    List.map (\(left, top) ->
       ((prototypeId, color, name, (deskWidth, deskHeight)), (left, top))
    ) all
