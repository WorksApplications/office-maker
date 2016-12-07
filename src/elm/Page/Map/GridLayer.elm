module Page.Map.GridLayer exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Lazy as Lazy

import Model.Scale as Scale exposing (Scale)
import Model.Floor as Floor exposing (Floor)
import View.Styles as Styles

import Page.Map.Model as Model exposing (Model)


view : Model -> Floor -> Html msg
view model floor =
  Lazy.lazy3 viewHelp model.scale model.gridSize floor


viewHelp : Scale -> Int -> Floor -> Html msg
viewHelp scale gridSize floor =
  let
    -- 10m = 100 unit = 100 * 8px(gridSize) = 800px (on image)
    intervalPxOnScreen =
      Scale.imageToScreen scale (50 * gridSize)

    wh =
      Scale.imageToScreenForPosition
        scale
        { x = Floor.width floor
        , y = Floor.height floor
        }

    width = wh.x

    height = wh.y

    lefts = List.map ((*) intervalPxOnScreen) (List.range 1 (width // intervalPxOnScreen))

    tops = List.map ((*) intervalPxOnScreen) (List.range 1 (height // intervalPxOnScreen))

    vertical = List.map (Lazy.lazy verticalLine) lefts

    horizontal = List.map (Lazy.lazy horizontalLine) tops
  in
    div [ style Styles.gridLayer ] ( vertical ++ horizontal )

verticalLine : Int -> Html msg
verticalLine left =
  div [ style (Styles.gridLayerVirticalLine left) ] []


horizontalLine : Int -> Html msg
horizontalLine top =
  div [ style (Styles.gridLayerHorizontalLine top) ] []
