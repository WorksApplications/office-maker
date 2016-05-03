effect module Util.Keys where { subscription = MySub } exposing
  ( downs
  , ups
  )

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
