module Model.Scale exposing (..) -- where

type Action = ScaleUp | ScaleDown

type alias Model =
  { scaleDown : Int
  }

init : Model
init =
  { scaleDown = 0
  }

update : Action -> Model -> Model
update action model =
  case action of
    ScaleUp ->
      { model | scaleDown = max 0 (model.scaleDown - 1) }
    ScaleDown ->
      { model | scaleDown = min 2 (model.scaleDown + 1) }

screenToImageForPosition : Model -> (Int, Int) -> (Int, Int)
screenToImageForPosition model (screenX, screenY) =
  ( screenToImage model screenX
  , screenToImage model screenY)

imageToScreenForPosition : Model -> (Int, Int) -> (Int, Int)
imageToScreenForPosition model (imageX, imageY) =
  ( imageToScreen model imageX
  , imageToScreen model imageY)

imageToScreenForRect : Model -> (Int, Int, Int, Int) -> (Int, Int, Int, Int)
imageToScreenForRect model (x, y, w, h) =
  ( imageToScreen model x
  , imageToScreen model y
  , imageToScreen model w
  , imageToScreen model h
  )

screenToImageForRect : Model -> (Int, Int, Int, Int) -> (Int, Int, Int, Int)
screenToImageForRect model (x, y, w, h) =
  ( screenToImage model x
  , screenToImage model y
  , screenToImage model w
  , screenToImage model h
  )

screenToImage : Model -> Int -> Int
screenToImage model imageLength =
  imageLength * (2 ^ model.scaleDown)

imageToScreen : Model -> Int -> Int
imageToScreen model screenLength =
  screenLength // (2 ^ model.scaleDown)

imageToScreenRatio : Model -> Float
imageToScreenRatio model =
  1.0 / (2 ^ (toFloat model.scaleDown))

ratio : Model -> Model -> Float
ratio old new =
  (toFloat (2 ^ old.scaleDown)) / (toFloat (2 ^ new.scaleDown))
