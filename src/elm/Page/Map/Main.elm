module Page.Map.Main exposing (..)

import Navigation
import Page.Map.Model exposing (Model)
import Page.Map.Update as Update exposing (Flags)
import Page.Map.View as View
import Page.Map.Msg exposing (Msg)
import Html.Lazy exposing (lazy)


main : Program Flags Model Msg
main =
    Navigation.programWithFlags Update.parseURL
        { init = Update.init
        , view = lazy View.view
        , update = Update.update
        , subscriptions = Update.subscriptions
        }
