module Model.ColorPalette exposing (..)

import String

type alias ColorPalette =
  { backgroundColors : List String
  , textColors : List String
  }


init : List String -> ColorPalette
init master =
  { backgroundColors = Debug.log "master"
      master
  , textColors =
      List.map
        (\color -> if color == "transparent" || String.startsWith "rgba" color then "#000" else color)
        master
  }
