module Model.ColorPalette exposing (..)

import Util.ListUtil as ListUtil


type alias ColorPalette =
  { backgroundColors : List String
  , textColors : List String
  }


empty : ColorPalette
empty =
  { backgroundColors = []
  , textColors = []
  }


setColorAt : Int -> String -> ColorPalette -> ColorPalette
setColorAt index color colorPalette =
  { colorPalette
  | textColors = ListUtil.setAt index color colorPalette.textColors
  }


setBackgroundColorAt : Int -> String -> ColorPalette -> ColorPalette
setBackgroundColorAt index color colorPalette =
  { colorPalette
  | backgroundColors = ListUtil.setAt index color colorPalette.backgroundColors
  }
