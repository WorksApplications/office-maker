module API.Cache exposing (..)

import Task exposing (..)
import Json.Encode as E exposing (Value)
import Json.Decode as D exposing (Decoder)
import PersistentCache as Cache
import Model.Scale as Scale exposing (Scale)
import Model.I18n as I18n exposing (..)
import Util.DecodeUtil exposing (..)


type alias Cache =
    Cache.Cache UserState


cache : Cache
cache =
    Cache.cache
        { name = "userState"
        , version = 1
        , kilobytes = 1024
        , decode = decode
        , encode = encode
        }


defaultUserState : Language -> UserState
defaultUserState lang =
    { scale = Scale.default
    , offset = { x = 35, y = 35 }
    , lang = lang
    }


get : Cache -> Task x (Maybe UserState)
get cache =
    Cache.get cache "userState"


getWithDefault : Cache -> UserState -> Task x UserState
getWithDefault cache defaultState =
    Cache.get cache "userState"
        |> andThen
            (\maybeState ->
                case maybeState of
                    Just state ->
                        Task.succeed state

                    Nothing ->
                        put cache defaultState
                            |> Task.map (\_ -> defaultState)
            )


put : Cache -> UserState -> Task x ()
put cache state =
    Cache.add cache "userState" state


clear : Cache -> Task x ()
clear cache =
    Cache.clear cache


type alias Position =
    { x : Int
    , y : Int
    }


type alias UserState =
    { scale : Scale
    , offset : Position
    , lang : Language
    }


decode : Decoder UserState
decode =
    D.map3
        (\scale ( x, y ) lang ->
            { scale = Scale.init scale
            , offset = { x = x, y = y }
            , lang =
                if lang == "JA" then
                    I18n.JA
                else
                    I18n.EN
            }
        )
        (D.field "scale" D.int)
        (D.field "offset" <| tuple2 (,) D.int D.int)
        (D.field "lang" D.string)


encode : UserState -> Value
encode state =
    E.object
        [ ( "scale", E.int state.scale.scaleDown )
        , ( "offset", E.list [ E.int state.offset.x, E.int state.offset.y ] )
        , ( "lang"
          , E.string <|
                case state.lang of
                    JA ->
                        "JA"

                    EN ->
                        "EN"
          )
        ]
