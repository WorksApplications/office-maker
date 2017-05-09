port module Page.Master.Main exposing (..)

import Html
import Page.Master.Model exposing (Model)
import Page.Master.Msg exposing (Msg)
import Page.Master.Update exposing (Flags, init, update, subscriptions)
import Page.Master.View exposing (view)


port removeToken : {} -> Cmd msg


port tokenRemoved : ({} -> msg) -> Sub msg


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update removeToken
        , subscriptions = subscriptions
        }
