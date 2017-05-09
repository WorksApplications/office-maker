module Page.Map.ClipboardOptionsView exposing (Form, init, view)

import Html exposing (..)
import Html.Attributes as Attributes exposing (..)
import Html.Events exposing (..)
import CoreType exposing (..)
import View.Styles as Styles


type alias Form =
    { width : Maybe String
    , height : Maybe String
    }


init : Form
init =
    Form Nothing Nothing


maybeError : Result e a -> Maybe e
maybeError result =
    case result of
        Ok _ ->
            Nothing

        Err message ->
            Just message


type Msg
    = ChangeWidth (Result String Int)
    | ChangeHeight (Result String Int)


update : Size -> Form -> Msg -> ( Form, Maybe Size )
update size form msg =
    case msg of
        ChangeWidth result ->
            case result of
                Ok width ->
                    ( { form | width = Nothing }, Just { size | width = width } )

                Err message ->
                    ( { form | width = Just message }, Nothing )

        ChangeHeight result ->
            case result of
                Ok height ->
                    ( { form | height = Nothing }, Just { size | height = height } )

                Err message ->
                    ( { form | height = Just message }, Nothing )


view : (( Form, Maybe Size ) -> msg) -> Form -> Size -> Html msg
view tagger form size =
    let
        widthLabel =
            label [ style Styles.widthHeightLabel ] [ text "幅" ]

        heightLabel =
            label [ style Styles.widthHeightLabel ] [ text "高さ" ]
    in
        div []
            [ div [ style [ ( "font-size", "13px" ) ] ] [ text "スプレッドシート貼付オプション" ]
            , div
                [ style Styles.floorSizeInputContainer ]
                [ widthLabel
                , sizeInput size.width |> Html.map ChangeWidth
                , heightLabel
                , sizeInput size.height |> Html.map ChangeHeight
                ]
                |> Html.map (update size form >> tagger)
            ]


sizeInput : Int -> Html (Result String Int)
sizeInput intValue =
    input
        [ style Styles.realSizeInput
        , value (toString intValue)
        , onInput validate
        ]
        []


validate : String -> Result String Int
validate value =
    value
        |> String.toInt
        |> Result.mapError (always "only numbers are allowed")
        |> Result.andThen validateInt


validateInt : Int -> Result String Int
validateInt i =
    if i > 0 then
        Ok i
    else
        Err "only positive numbers are allowed"
