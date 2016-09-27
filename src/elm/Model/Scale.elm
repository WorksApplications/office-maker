module Model.Scale exposing (..)


type Action = ScaleUp | ScaleDown


type alias Scale =
  { scaleDown : Int
  }


default : Scale
default = init 0


init : Int -> Scale
init scaleDown =
  { scaleDown = scaleDown
  }


update : Action -> Scale -> Scale
update action model =
  case action of
    ScaleUp ->
      { model | scaleDown = max 0 (model.scaleDown - 1) }

    ScaleDown ->
      { model | scaleDown = min 4 (model.scaleDown + 1) }


screenToImageForPosition : Scale -> (Int, Int) -> (Int, Int)
screenToImageForPosition model (screenX, screenY) =
  ( screenToImage model screenX
  , screenToImage model screenY)


imageToScreenForPosition : Scale -> (Int, Int) -> (Int, Int)
imageToScreenForPosition model (imageX, imageY) =
  ( imageToScreen model imageX
  , imageToScreen model imageY)


imageToScreenForRect : Scale -> (Int, Int, Int, Int) -> (Int, Int, Int, Int)
imageToScreenForRect model (x, y, w, h) =
  ( imageToScreen model x
  , imageToScreen model y
  , imageToScreen model w
  , imageToScreen model h
  )


screenToImageForRect : Scale -> (Int, Int, Int, Int) -> (Int, Int, Int, Int)
screenToImageForRect model (x, y, w, h) =
  ( screenToImage model x
  , screenToImage model y
  , screenToImage model w
  , screenToImage model h
  )


screenToImage : Scale -> Int -> Int
screenToImage model imageLength =
  imageLength * (2 ^ model.scaleDown)


imageToScreen : Scale -> Int -> Int
imageToScreen model screenLength =
  screenLength // (2 ^ model.scaleDown)


imageToScreenRatio : Scale -> Float
imageToScreenRatio model =
  1.0 / (2 ^ (toFloat model.scaleDown))


ratio : Scale -> Scale -> Float
ratio old new =
  (toFloat (2 ^ old.scaleDown)) / (toFloat (2 ^ new.scaleDown))
