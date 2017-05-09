module Page.Map.GridLayer exposing (view)

import Svg exposing (..)
import Svg.Attributes exposing (..)
import Svg.Lazy exposing (..)
import Model.Scale as Scale exposing (Scale)
import Model.Floor as Floor exposing (Floor)
import Page.Map.Model as Model exposing (Model)


view : Model -> Floor -> Svg msg
view model floor =
    lazy3 viewHelp model.scale model.gridSize floor


viewHelp : Scale -> Int -> Floor -> Svg msg
viewHelp scale gridSize floor =
    let
        intervalPxOnScreen =
            50 * gridSize

        width =
            Floor.width floor

        height =
            Floor.height floor

        lefts =
            List.map ((*) intervalPxOnScreen) (List.range 1 (width // intervalPxOnScreen))

        tops =
            List.map ((*) intervalPxOnScreen) (List.range 1 (height // intervalPxOnScreen))

        vertical =
            List.map (lazy2 verticalLine height) lefts

        horizontal =
            List.map (lazy2 horizontalLine width) tops
    in
        g [] (vertical ++ horizontal)


verticalLine : Int -> Int -> Svg msg
verticalLine height left =
    Svg.path [ strokeDasharray "5,5", stroke "black", d ("M" ++ toString left ++ ",0V" ++ toString height) ] []


horizontalLine : Int -> Int -> Svg msg
horizontalLine width top =
    Svg.path [ strokeDasharray "5,5", stroke "black", d ("M0," ++ toString top ++ "H" ++ toString width) ] []
