module API.Cache exposing (..)

import Task exposing (..)
import Json.Encode as E exposing (Value)
import Json.Decode as D exposing ((:=), Decoder)
import PersistentCache as Cache
import Model.Scale as Scale exposing (Scale)
import Model.I18n as I18n exposing (..)


type alias Cache = Cache.Cache UserState


cache : Cache
cache =
  Cache.cache
    { name = "userState"
    , version = 1
    , kilobytes = 1024
    , decode = decode
    , encode = encode
    }


defaultUserState : UserState
defaultUserState =
  { scale = Scale.default
  , offset = (35, 35)
  , lang = JA
  }


get : Cache -> Task x (Maybe UserState)
get cache =
  Cache.get cache "userState"


getWithDefault : Cache -> UserState -> Task x UserState
getWithDefault cache defaultState =
  Cache.get cache "userState" `andThen` \maybeState ->
  case maybeState of
    Just state ->
      Task.succeed state

    Nothing ->
      put cache defaultState `andThen` \_ ->
      Task.succeed defaultState


put : Cache -> UserState -> Task x ()
put cache state =
  Cache.add cache "userState" state


clear : Cache -> Task x ()
clear cache =
  Cache.clear cache


type alias UserState =
  { scale : Scale
  , offset : (Int, Int)
  , lang : Language
  }


decode : Decoder UserState
decode =
  D.object3
  (\scale offset lang ->
    { scale = Scale.init scale
    , offset = offset
    , lang = if lang == "JA" then I18n.JA else I18n.EN
    }
  )
  ("scale" := D.int)
  ("offset" := D.tuple2 (,) D.int D.int)
  ("lang" := D.string)



encode : UserState -> Value
encode state =
  E.object
    [ ("scale", E.int state.scale.scaleDown)
    , ("offset", E.list [ E.int (fst state.offset), E.int (snd state.offset) ] )
    , ("lang", E.string <| case state.lang of
        JA -> "JA"
        EN -> "EN"
      )
    ]
