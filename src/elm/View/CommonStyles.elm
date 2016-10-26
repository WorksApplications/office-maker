module View.CommonStyles exposing (..)

import Util.StyleUtil exposing (..)
import String

type alias S = List (String, String)


invertedTextColor : String
invertedTextColor = "#fff"


inputTextColor : String
inputTextColor = "#333"


selectColor : String
selectColor = "#69e"


errorTextColor : String
errorTextColor = "#d45"


hoverBackgroundColor : String
hoverBackgroundColor = "#9ce"


noMargin : S
noMargin =
  [ ( "margin", "0") ]


noPadding : S
noPadding =
  [ ( "padding", "0") ]


flex : S
flex =
  [ ( "display", "flex") ]


rect : (Int, Int, Int, Int) -> S
rect (x, y, w, h) =
  [ ("top", px y)
  , ("left", px x)
  , ("width", px w)
  , ("height", px h)
  ]


absoluteRect : (Int, Int, Int, Int) -> S
absoluteRect rect' =
  ("position", "absolute") :: (rect rect')


card : S
card =
  [ ("padding", "20px")
  , ("box-shadow", "rgba(0, 0, 0, 0.08451) -2px 2px 4px inset")
  ]


formControl : S
formControl =
  [ ("margin-bottom", "6px")
  ]


button : S
button =
  [ ("display", "block")
  , ("text-align", "center")
  , ("width", "100%")
  , ("padding", "6px 12px")
  , ("box-sizing", "border-box")
  , ("font-size", "13px")
  , ("cursor", "pointer")
  ]


defaultButton : S
defaultButton =
  button ++
    [ ("background-color", "#eee")
    , ("border", "solid 1px #aaa")
    ]


primaryButton : S
primaryButton =
  button ++
    [ ("background-color", "rgb(100, 180, 85)")
    , ("color", invertedTextColor)
    , ("border", "solid 1px rgb(100, 180, 85)")
    ]


dangerButton : S
dangerButton =
  button ++
    [ ("background-color", "rgb(221, 116, 116)")
    , ("color", invertedTextColor)
    , ("border", "solid 1px rgb(221, 116, 116)")
    ]


input : S
input =
  [ ("color", inputTextColor)
  , ("width", "100%")
  , ("background-color", "#fff")
  , ("box-shadow", "inset 0 1px 2px rgba(0,0,0,0.075)")
  , ("border", "1px solid #ddd")
  , ("padding", "6px 12px")
  , ("box-sizing", "border-box")
  , ("font-size", "13px")
  ]


popup : Int -> String -> S
popup padding position =
  [ ("box-sizing", "border-box")
  , ("padding", px padding)
  , ("background-color", "#fff")
  , ("position", position)
  ]


modalBackground : Int -> S
modalBackground zIndex =
  [ ("background-color", "rgba(0,0,0,0.5)")
  , ("position", "fixed")
  , ("left", "0")
  , ("right", "0")
  , ("top", "0")
  , ("bottom", "0")
  , ("z-index", toString zIndex)
  ]


dialogWithSize : Int -> Int -> Int -> S
dialogWithSize zIndex width height =
  popup 20 "fixed" ++
    [ ("margin", "auto")
    , ("left", "0")
    , ("right", "0")
    , ("top", "0")
    , ("bottom", "0")
    , ("width", px width)
    , ("height", px height)
    , ("z-index", toString zIndex)
    ]


dialogWithMarginParcentage : Int -> Int -> Int -> S
dialogWithMarginParcentage zIndex top left =
  popup 20 "fixed" ++
    [ ("left", percent left)
    , ("right", percent left)
    , ("top", percent top)
    , ("bottom", percent top)
    , ("z-index", toString zIndex)
    ]


dialogFooter : S
dialogFooter =
  [ ("position", "absolute")
  , ("left", "0")
  , ("bottom", "0")
  , ("display", "flex")
  , ("padding", px 20)
  , ("width", "100%")
  , ("box-sizing", "border-box")
  ]
