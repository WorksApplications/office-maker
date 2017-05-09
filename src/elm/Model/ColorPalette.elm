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


setTextColorAt : Int -> String -> ColorPalette -> ColorPalette
setTextColorAt index color colorPalette =
    { colorPalette
        | textColors = ListUtil.setAt index color colorPalette.textColors
    }


setBackgroundColorAt : Int -> String -> ColorPalette -> ColorPalette
setBackgroundColorAt index color colorPalette =
    { colorPalette
        | backgroundColors = ListUtil.setAt index color colorPalette.backgroundColors
    }


addTextColorToLast : String -> ColorPalette -> ColorPalette
addTextColorToLast color colorPalette =
    { colorPalette
        | textColors =
            colorPalette.textColors
                |> List.reverse
                |> ((::) color)
                |> List.reverse
    }


addBackgroundColorToLast : String -> ColorPalette -> ColorPalette
addBackgroundColorToLast color colorPalette =
    { colorPalette
        | backgroundColors =
            colorPalette.backgroundColors
                |> List.reverse
                |> ((::) color)
                |> List.reverse
    }


deleteTextColorAt : Int -> ColorPalette -> ColorPalette
deleteTextColorAt index colorPalette =
    { colorPalette
        | textColors = ListUtil.deleteAt index colorPalette.textColors
    }


deleteBackgroundColorAt : Int -> ColorPalette -> ColorPalette
deleteBackgroundColorAt index colorPalette =
    { colorPalette
        | backgroundColors = ListUtil.deleteAt index colorPalette.backgroundColors
    }
