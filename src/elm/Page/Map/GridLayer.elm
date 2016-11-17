module Page.Map.GridLayer exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)

import Model.Scale as Scale
import Model.Floor as Floor exposing (Floor)
import View.Styles as Styles

import Page.Map.Model as Model exposing (Model)


view : Model -> Floor -> Html msg
view model floor =
  let
    -- 10m = 100 unit = 100 * 8px(gridSize) = 800px (on image)
    intervalPxOnScreen =
      Scale.imageToScreen model.scale (50 * model.gridSize)

    wh =
      Scale.imageToScreenForPosition
        model.scale
        { x = Floor.width floor
        , y = Floor.height floor
        }

    width = wh.x

    height = wh.y

    lefts = List.map ((*) intervalPxOnScreen) (List.range 1 (width // intervalPxOnScreen))

    tops = List.map ((*) intervalPxOnScreen) (List.range 1 (height // intervalPxOnScreen))

    vertical = List.map verticalLine lefts

    horizontal = List.map horizontalLine tops
  in
    div [ style Styles.gridLayer ] ( vertical ++ horizontal )


verticalLine : Int -> Html msg
verticalLine left =
  div [ style (Styles.gridLayerVirticalLine left) ] []


horizontalLine : Int -> Html msg
horizontalLine top =
  div [ style (Styles.gridLayerHorizontalLine top) ] []
