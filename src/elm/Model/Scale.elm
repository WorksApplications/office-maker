module Model.Scale exposing (..)

import CoreType exposing (..)


-- CONFIG


minScale : Int
minScale =
    0


maxScale : Int
maxScale =
    8


defaultScale : Int
defaultScale =
    4


step : Float
step =
    1.414



-- TEA


type alias Scale =
    { scaleDown : Int
    }


default : Scale
default =
    init defaultScale


init : Int -> Scale
init scaleDown =
    Scale scaleDown


type Msg
    = ScaleUp
    | ScaleDown


update : Msg -> Scale -> Scale
update msg scale =
    case msg of
        ScaleUp ->
            { scale | scaleDown = max minScale (scale.scaleDown - 1) }

        ScaleDown ->
            { scale | scaleDown = min maxScale (scale.scaleDown + 1) }



-- FUNCTIONS


screenToImageForPosition : Scale -> Position -> Position
screenToImageForPosition scale screenPosition =
    Position
        (screenToImage scale screenPosition.x)
        (screenToImage scale screenPosition.y)


imageToScreenForPosition : Scale -> Position -> Position
imageToScreenForPosition scale imagePosition =
    Position
        (imageToScreen scale imagePosition.x)
        (imageToScreen scale imagePosition.y)


imageToScreenForSize : Scale -> Size -> Size
imageToScreenForSize scale { width, height } =
    Size (imageToScreen scale width) (imageToScreen scale height)


screenToImageForSize : Scale -> Size -> Size
screenToImageForSize scale { width, height } =
    Size (screenToImage scale width) (screenToImage scale height)


screenToImage : Scale -> Int -> Int
screenToImage scale imageLength =
    round (toFloat imageLength * step ^ toFloat scale.scaleDown)


imageToScreen : Scale -> Int -> Int
imageToScreen scale screenLength =
    round (toFloat screenLength / step ^ toFloat scale.scaleDown)


imageToScreenRatio : Scale -> Float
imageToScreenRatio scale =
    1.0 / step ^ (toFloat scale.scaleDown)


ratio : Scale -> Scale -> Float
ratio old new =
    (step ^ toFloat old.scaleDown) / (step ^ toFloat new.scaleDown)
