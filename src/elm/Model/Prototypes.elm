module Model.Prototypes exposing (..)

import Model.Prototype exposing (Prototype)
import Model.ObjectsOperation as ObjectsOperation

import Util.ListUtil exposing (..)


type alias PositionedPrototype =
  (Prototype, (Int, Int))


type alias Prototypes =
  { data : List Prototype
  , selected : Int
  }


type alias Position =
  { x : Int
  , y : Int
  }


type alias Size =
  { width : Int
  , height : Int
  }


gridSize : Int
gridSize = 8 --TODO


init : List Prototype -> Prototypes
init data =
  { data = data
  , selected = 0 -- index
  }


type Msg
  = SelectPrev
  | SelectNext


prev : Msg
prev = SelectPrev


next : Msg
next = SelectNext


update : Msg -> Prototypes -> Prototypes
update msg model =
  case msg of
    SelectPrev ->
      { model |
        selected = max 0 (model.selected - 1) -- fail safe
      }

    SelectNext ->
      { model |
        selected = min (List.length model.data - 1) (model.selected + 1) -- fail safe
      }


register : Prototype -> Prototypes -> Prototypes
register prototype model =
  let
    newPrototypes = model.data ++ [prototype]
  in
    { model |
      data = newPrototypes
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
        Just prototype -> prototype
        Nothing -> Debug.crash "no prototypes found"


prototypes : Prototypes -> List (Prototype, Bool)
prototypes model =
  List.indexedMap (\index prototype ->
      (prototype, model.selected == index)
    ) model.data


stampIndices : Bool -> (Int, Int) -> (Int, Int) -> (Int, Int) -> (List Int, List Int)
stampIndices horizontal (deskWidth, deskHeight) (x1_, y1_) (x2_, y2_) =
  let
    (amountX, amountY) =
      if horizontal then
        let
          amountX = (abs (x2_ - x1_) + deskWidth // 2) // deskWidth

          amountY = if abs (y2_ - y1_) > (deskHeight // 2) then 1 else 0
        in
         (amountX, amountY)
      else
        let
          amountX = if abs (x2_ - x1_) > (deskWidth // 2) then 1 else 0

          amountY = (abs (y2_ - y1_) + deskHeight // 2) // deskHeight
        in
          (amountX, amountY)
  in
    ( List.map (\i -> if x2_ > x1_ then i else -i) (List.range 0 amountX)
    , List.map (\i -> if y2_ > y1_ then i else -i) (List.range 0 amountY)
    )


generateAllCandidatePosition : (Int, Int) -> (Int, Int) -> (List Int, List Int) -> List (Int, Int)
generateAllCandidatePosition (deskWidth, deskHeight) (centerLeft, centerTop) (indicesX, indicesY) =
  let
    lefts =
      List.map (\index -> centerLeft + deskWidth * index) indicesX

    tops =
      List.map (\index -> centerTop + deskHeight * index) indicesY
  in
    List.concatMap (\left -> List.map (\top -> (left, top)) tops) lefts


positionedPrototypesOnDragging : Int -> Prototype -> Position -> Position -> List PositionedPrototype
positionedPrototypesOnDragging gridSize prototype xy1 xy2 = -- imagePos
  let
    x1 = xy1.x
    y1 = xy1.y
    x2 = xy2.x
    y2 = xy2.y

    deskSize = (prototype.width, prototype.height)

    flip (w, h) = (h, w)

    horizontal =
      abs (x2 - x1) > abs (y2 - y1)

    (deskWidth, deskHeight) =
      if horizontal then flip deskSize else deskSize

    (indicesX, indicesY) =
      stampIndices horizontal (deskWidth, deskHeight) (x1, y1) (x2, y2)

    center =
      ObjectsOperation.fitPositionToGrid
        gridSize
        { x = x1 - Tuple.first deskSize // 2
        , y = y1 - Tuple.second deskSize // 2
        }

    all =
      generateAllCandidatePosition
        (deskWidth, deskHeight)
        (center.x, center.y)
        (indicesX, indicesY)

    prototype_ =
      { prototype
      | width = deskWidth
      , height = deskHeight
      }
  in
    List.map ((,) prototype_) all
