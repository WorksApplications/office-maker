module Model.ColorPalette exposing (..)

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
  | textColors = setAt index color colorPalette.textColors
  }


setBackgroundColorAt : Int -> String -> ColorPalette -> ColorPalette
setBackgroundColorAt index color colorPalette =
  { colorPalette
  | backgroundColors = setAt index color colorPalette.backgroundColors
  }


setAt : Int -> a -> List a -> List a
setAt index value list =
  case list of
    head :: tail ->
      if index == 0 then
        value :: tail
      else
        head :: setAt (index - 1) value tail

    [] ->
      list
