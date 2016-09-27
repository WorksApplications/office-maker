module API.Cache exposing (..)

import Task exposing (..)
import Json.Encode as E exposing (Value)
import Json.Decode as D exposing ((:=), Decoder)
import PersistentCache as Cache
import Model.Scale as Scale exposing (Scale)
import Model.I18n as I18n exposing (..)


cache : Cache.Cache UserState
cache =
  Cache.cache
    { name = "userState"
    , version = 1
    , kilobytes = 1024
    , decode = decode
    , encode = encode
    }


getState : Task x (Maybe UserState)
getState =
  Cache.get cache "userState"


putState : UserState -> Task x ()
putState model =
  Cache.add cache "userState" model


type alias UserState =
  { scale : Scale
  , shift : (Int, Int)
  , lang : Language
  }


decode : Decoder UserState
decode =
  D.object3
  (\scale shift lang ->
    { scale = Scale.init scale
    , shift = shift
    , lang = if lang == "JA" then I18n.JA else I18n.EN
    }
  )
  ("scale" := D.int)
  ("shift" := D.tuple2 (,) D.int D.int)
  ("lang" := D.string)



encode : UserState -> Value
encode state =
  E.object
    [ ("scale", E.int state.scale.scaleDown)
    , ("shift", E.list [ E.int (fst state.shift), E.int (snd state.shift) ] )
    , ("lang", E.string <| case state.lang of
        JA -> "JA"
        EN -> "EN"
      )
    ]
