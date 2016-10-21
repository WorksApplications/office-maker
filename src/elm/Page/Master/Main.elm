port module Page.Master.Main exposing (..)

import Html.App as App
-- import Page.Master.Model exposing (Model)
import Page.Master.Update exposing (Flags, init, update)
import Page.Master.View exposing (view)

port removeToken : {} -> Cmd msg

port tokenRemoved : ({} -> msg) -> Sub msg


main : Program Flags
main =
  App.programWithFlags
    { init = init
    , view = view
    , update = update removeToken
    , subscriptions = \_ -> Sub.none
    }
