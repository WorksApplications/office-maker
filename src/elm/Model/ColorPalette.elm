module Model.ColorPalette exposing (..)

type alias ColorPalette =
  { backgroundColors : List String
  , textColors : List String
  }


type alias ColorEntity =
  { id : String
  , ord : Int
  , type_ : String
  , color : String
  }


init : List ColorEntity -> ColorPalette
init entities =
  let
    sorted =
      List.sortBy (.ord) entities

    backgroundColors =
      List.filterMap (\e ->
        if e.type_ == "backgroundColor" then
          Just e.color
        else
          Nothing
      )
      sorted

    textColors =
      List.filterMap (\e ->
        if e.type_ == "color" then
          Just e.color
        else
          Nothing
      )
      sorted
  in
    { backgroundColors = backgroundColors
    , textColors = textColors
    }
