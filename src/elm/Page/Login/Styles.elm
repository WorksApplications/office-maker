module Page.Login.Styles exposing (..)

import View.CommonStyles as Styles


type alias S =
    List ( String, String )


loginContainer : S
loginContainer =
    [ ( "margin-left", "auto" )
    , ( "margin-right", "auto" )
    , ( "margin-top", "40px" )
    , ( "margin-bottom", "auto" )
    , ( "width", "400px" )
    , ( "padding", "15px" )
    , ( "border", "solid 1px #aaa" )
    ]


loginCaption : S
loginCaption =
    []


loginError : S
loginError =
    [ ( "color", Styles.errorTextColor )
    , ( "margin-bottom", "15px" )
    ]


loginSubmitButton : S
loginSubmitButton =
    Styles.primaryButton ++ [ ( "margin-top", "20px" ), ( "width", "100%" ) ]


formInput : S
formInput =
    Styles.input
        ++ [ ( "padding", "7px 8px" )
           , ( "vertical-align", "middle" )
           , ( "font-size", "13px" )
           , ( "margin-top", "5px" )
           , ( "margin-bottom", "15px" )
           ]
