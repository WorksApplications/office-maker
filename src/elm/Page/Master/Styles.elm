module Page.Master.Styles exposing (..)

import View.CommonStyles as Styles


type alias S =
    List ( String, String )


validationError : S
validationError =
    [ ( "color", Styles.errorTextColor )
    ]
