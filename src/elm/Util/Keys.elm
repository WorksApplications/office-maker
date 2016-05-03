effect module Util.Keys where { subscription = MySub } exposing
  ( Model
  , Event(..)
  , init'
  , update
  , downs
  , ups
  )

import Char
import Dict
import Dom.LowLevel as Dom
import Json.Decode as Json exposing ((:=))
import Process
import Task exposing (Task)


ups : (Int -> msg) -> Sub msg
ups tagger =
  subscription (MySub "keyup" tagger)

downs : (Int -> msg) -> Sub msg
downs tagger =
  subscription (MySub "keydown" tagger)


keyCode : Json.Decoder Int
keyCode =
  Json.at [ "keyCode" ] Json.int

type Event =
    Ctrl
  | Shift
  | Del
  | A
  | C
  | F
  | S
  | V
  | X
  | Y
  | Z
  | Enter
  | LeftArrow
  | UpArrow
  | RightArrow
  | DownArrow
  | Other Int
  | None

type alias Model =
  { ctrl : Bool
  , shift : Bool
  }

init' : Model
init' =
  { ctrl = False
  , shift = False
  }

update : Bool -> Int -> Model -> (Model, Event)
update isDown keyCode model =
  let
    event =
      if not isDown then None
      else if keyCode == 13 then Enter
      else if keyCode == 16 then Shift
      else if keyCode == 17 then Ctrl
      else if keyCode == 46 then Del
      else if keyCode == (Char.toCode 'A') then A
      else if keyCode == (Char.toCode 'C') then C
      else if keyCode == (Char.toCode 'F') then F
      else if keyCode == (Char.toCode 'S') then S
      else if keyCode == (Char.toCode 'V') then V
      else if keyCode == (Char.toCode 'X') then X
      else if keyCode == (Char.toCode 'Y') then Y
      else if keyCode == (Char.toCode 'Z') then Z
      else if keyCode == 37 then LeftArrow
      else if keyCode == 38 then UpArrow
      else if keyCode == 39 then RightArrow
      else if keyCode == 40 then DownArrow
      else Other keyCode
    newModel =
      if keyCode == 16 then
        { model | shift = isDown }
      else if keyCode == 17 then
        { model | ctrl = isDown }
      else
        model
  in
    (newModel, event)



-- SUBSCRIPTIONS

type MySub msg
  = MySub String (Int -> msg)


subMap : (a -> b) -> MySub a -> MySub b
subMap func (MySub category tagger) =
  MySub category (tagger >> func)

-- EFFECT MANAGER STATE


type alias State msg =
  Dict.Dict String (Watcher msg)


type alias Watcher msg =
  { taggers : List (Int -> msg)
  , pid : Process.Id
  }



-- CATEGORIZE SUBSCRIPTIONS


type alias SubDict msg =
  Dict.Dict String (List (Int -> msg))


categorize : List (MySub msg) -> SubDict msg
categorize subs =
  categorizeHelp subs Dict.empty


categorizeHelp : List (MySub msg) -> SubDict msg -> SubDict msg
categorizeHelp subs subDict =
  case subs of
    [] ->
      subDict

    MySub category tagger :: rest ->
      categorizeHelp rest <|
        Dict.update category (categorizeHelpHelp tagger) subDict


categorizeHelpHelp : a -> Maybe (List a) -> Maybe (List a)
categorizeHelpHelp value maybeValues =
  case maybeValues of
    Nothing ->
      Just [value]

    Just values ->
      Just (value :: values)



-- EFFECT MANAGER


init : Task Never (State msg)
init =
  Task.succeed Dict.empty


type alias Msg =
  { category : String
  , keyCode : Int
  }


(&>) : Task a b -> Task a c -> Task a c
(&>) t1 t2 = t1 `Task.andThen` \_ -> t2


onEffects : Platform.Router msg Msg -> List (MySub msg) -> State msg -> Task Never (State msg)
onEffects router newSubs oldState =
  let
    leftStep category {pid} task =
      Process.kill pid &> task

    bothStep category {pid} taggers task =
      task
        `Task.andThen` \state ->

      Task.succeed
        (Dict.insert category (Watcher taggers pid) state)

    rightStep category taggers task =
      task
        `Task.andThen` \state ->

      Process.spawn (Dom.onDocument category keyCode (Platform.sendToSelf router << Msg category))
        `Task.andThen` \pid ->

      Task.succeed
        (Dict.insert category (Watcher taggers pid) state)
  in
    Dict.merge
      leftStep
      bothStep
      rightStep
      oldState
      (categorize newSubs)
      (Task.succeed Dict.empty)


onSelfMsg : Platform.Router msg Msg -> Msg -> State msg -> Task Never (State msg)
onSelfMsg router {category,keyCode} state =
  case Dict.get category state of
    Nothing ->
      Task.succeed state

    Just {taggers} ->
      let
        send tagger =
          Platform.sendToApp router (tagger keyCode)
      in
        Task.sequence (List.map send taggers)
          `Task.andThen` \_ ->

        Task.succeed state
