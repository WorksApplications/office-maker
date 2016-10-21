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
