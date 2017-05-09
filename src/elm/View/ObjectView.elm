module View.ObjectView exposing (EventOptions, noEvents, viewDesk, viewLabel)

import Char
import Json.Decode as Decode
import Svg exposing (..)
import Svg.Attributes as Attributes exposing (..)
import Svg.Lazy exposing (..)
import Html.Attributes
import Html.Events
import VirtualDom exposing (attributeNS)
import Mouse
import View.CommonStyles as CommonStyles
import View.Icons as Icons
import Model.Scale as Scale exposing (Scale)
import Page.Map.Emoji as Emoji
import Util.StyleUtil exposing (px)
import Util.HtmlUtil as HtmlUtil
import CoreType exposing (..)


type alias EventOptions msg =
    { onMouseDown : Maybe (Attribute msg)
    , onMouseUp : Maybe (Position -> msg)
    , onClick : Maybe msg
    , onStartEditingName : Maybe msg
    , onContextMenu : Maybe (Attribute msg)
    , onStartResize : Maybe (Position -> msg)
    }


noEvents : EventOptions msg
noEvents =
    { onMouseDown = Nothing
    , onMouseUp = Nothing
    , onClick = Nothing
    , onStartEditingName = Nothing
    , onContextMenu = Nothing
    , onStartResize = Nothing
    }


viewDesk : EventOptions msg -> Bool -> Position -> Size -> String -> String -> Float -> Bool -> Bool -> Scale -> Bool -> Svg msg
viewDesk eventOptions showPersonMatch pos size backgroundColor name fontSize selected isGhost scale personMatched =
    let
        personMatchIcon =
            if showPersonMatch then
                lazy2 personMatchingView name personMatched
            else
                text ""

        rectStyles_ =
            rectStyles size True False backgroundColor selected

        gStyles_ =
            gStyles isGhost pos

        nameView =
            objectLabelView size False "" fontSize pos size name
    in
        viewInternal eventOptions size selected scale gStyles_ rectStyles_ nameView personMatchIcon


viewLabel : EventOptions msg -> Position -> Size -> String -> String -> String -> Float -> Bool -> Bool -> Bool -> Bool -> Scale -> Svg msg
viewLabel eventOptions pos size backgroundColor fontColor name fontSize isEllipse selected isGhost rectVisible scale =
    let
        rectStyles_ =
            rectStyles size rectVisible True backgroundColor selected

        gStyles_ =
            gStyles isGhost pos

        nameView =
            objectLabelView size True fontColor fontSize pos size name
    in
        viewInternal eventOptions size selected scale gStyles_ rectStyles_ nameView (text "")


rectStyles : Size -> Bool -> Bool -> String -> Bool -> List (Svg.Attribute msg)
rectStyles size rectVisible dashed backgroundColor selected =
    [ width (px size.width)
    , height (px size.height)
    , fill backgroundColor
    , stroke
        (if selected then
            CommonStyles.selectColor
         else if rectVisible then
            "black"
         else
            "none"
        )
    , strokeWidth
        (if selected then
            "3"
         else
            "1.5"
        )
    ]
        ++ if (dashed && not selected) then
            [ strokeDasharray "5,5" ]
           else
            []


gStyles : Bool -> Position -> List (Svg.Attribute msg)
gStyles isGhost pos =
    [ transform ("translate(" ++ toString pos.x ++ "," ++ toString pos.y ++ ")")
    , fillOpacity
        (if isGhost then
            "0.5"
         else
            "1"
        )
    ]


viewInternal : EventOptions msg -> Size -> Bool -> Scale -> List (Svg.Attribute msg) -> List (Svg.Attribute msg) -> Svg msg -> Svg msg -> Svg msg
viewInternal eventOptions size selected scale gStyles rectStyles nameView personMatchIcon =
    let
        eventHandlers =
            (case eventOptions.onContextMenu of
                Just attr ->
                    [ attr ]

                Nothing ->
                    []
            )
                ++ (case eventOptions.onMouseDown of
                        Just attr ->
                            [ attr ]

                        Nothing ->
                            []
                   )
                ++ (case eventOptions.onMouseUp of
                        Just msg ->
                            [ Html.Events.onWithOptions "mouseup" { stopPropagation = True, preventDefault = False } Mouse.position |> Html.Attributes.map msg
                            ]

                        Nothing ->
                            []
                   )
                ++ (case eventOptions.onClick of
                        Just msg ->
                            [ Html.Events.onWithOptions "click" { stopPropagation = True, preventDefault = False } (Decode.succeed msg)
                            ]

                        Nothing ->
                            []
                   )
                ++ (case eventOptions.onStartEditingName of
                        Just msg ->
                            [ Html.Events.onDoubleClick msg ]

                        Nothing ->
                            []
                   )
    in
        g
            gStyles
            [ rect (rectStyles ++ eventHandlers) []
            , nameView
            , personMatchIcon
            , resizeGripView size selected scale eventOptions.onStartResize
            ]


resizeGripView : Size -> Bool -> Scale -> Maybe (Position -> msg) -> Svg msg
resizeGripView containerSize selected scale onStartResize =
    case ( selected, onStartResize ) of
        ( True, Just msg ) ->
            (lazy3 resizeGripViewHelp containerSize selected scale)
                |> Svg.map msg

        _ ->
            text ""


resizeGripViewHelp : Size -> Bool -> Scale -> Svg Position
resizeGripViewHelp containerSize selected scale =
    let
        screenWidth =
            round <| 8 / Scale.imageToScreenRatio scale

        screenHeight =
            screenWidth
    in
        rect
            [ class "object-resize-grip"
            , width (toString screenWidth)
            , height (toString screenHeight)
            , x (toString <| containerSize.width - screenWidth // 2)
            , y (toString <| containerSize.height - screenHeight // 2)
            , Html.Events.onWithOptions "mousedown" { stopPropagation = True, preventDefault = True } Mouse.position
            , stroke "black"
            , fill "white"
            , Attributes.cursor "nw-resize"
            ]
            []


personMatchingView : String -> Bool -> Svg msg
personMatchingView name personMatched =
    if name == "" then
        text ""
    else
        g []
            [ circle
                [ pointerEvents "none"
                , cx "10"
                , cy "10"
                , r "10"
                , fill
                    (if personMatched then
                        "rgb(102, 170, 102)"
                     else
                        "rgb(204, 204, 204)"
                    )
                ]
                []
            , lazy
                (if personMatched then
                    Icons.personMatched
                 else
                    Icons.personNotMatched
                )
                1
            ]


type LabelRow
    = TextRow String
    | ImageRow String String


objectLabelView : Size -> Bool -> String -> Float -> Position -> Size -> String -> Svg msg
objectLabelView containerSize canBeEmoji color fontSize_ screenPos screenSize name =
    let
        fragments =
            if canBeEmoji then
                Emoji.split name
            else
                [ Emoji.TextNode name ]
    in
        fragments
            |> List.concatMap
                (\fragment ->
                    case fragment of
                        Emoji.TextNode s ->
                            String.trim s
                                |> breakWords containerSize.width fontSize_
                                |> List.map TextRow

                        Emoji.Image original url ->
                            [ ImageRow original url ]
                )
            |> viewLabelRow containerSize 0.2 fontSize_
            |> g
                [ transform ("translate(0," ++ (toString <| toFloat containerSize.height / 2) ++ ")")
                , fill color
                , fontSize (toString fontSize_)
                , textAnchor "middle"
                , pointerEvents "none"
                ]


viewLabelRow : Size -> Float -> Float -> List LabelRow -> List (Svg msg)
viewLabelRow containerSize spaceHeight fontSize lines =
    let
        len =
            List.length lines

        top =
            (toFloat len + spaceHeight * toFloat (len - 1)) * (-0.5) + 0.5

        center =
            toFloat containerSize.width / 2
    in
        lines
            |> List.indexedMap
                (\i row ->
                    case row of
                        TextRow s ->
                            text_
                                [ y (toString (top + (1 + spaceHeight) * toFloat i) ++ "em")
                                , x (toString center)
                                , alignmentBaseline "middle"
                                , dominantBaseline "middle"
                                ]
                                [ text s ]

                        ImageRow original url ->
                            image
                                [ y (toString (top + (1 + spaceHeight) * toFloat i - fontSize / 2))
                                , x (toString (center - fontSize / 2))
                                , attributeNS "" "href" url
                                , alignmentBaseline "middle"
                                , dominantBaseline "middle"
                                , width (toString fontSize)
                                , height (toString fontSize)
                                ]
                                []
                )


words : String -> List String
words s =
    String.words s
        |> List.concatMap
            (\word ->
                word
                    |> String.toList
                    |> List.foldr
                        (\c ( cs, result ) ->
                            case cs of
                                [] ->
                                    ( [ c ], result )

                                prev :: rest ->
                                    if (Char.toCode c < 128) == (Char.toCode prev < 128) then
                                        ( c :: cs, result )
                                    else
                                        ( [ c ], String.fromList cs :: result )
                        )
                        ( [], [] )
                    |> (\( cs, result ) ->
                            if cs == [] then
                                result
                            else
                                String.fromList cs :: result
                       )
            )


breakWords : Int -> Float -> String -> List String
breakWords containerWidth fontSize s =
    breakWordsHelp containerWidth fontSize (words s) []
        |> List.reverse


breakWordsHelp : Int -> Float -> List String -> List String -> List String
breakWordsHelp containerWidth fontSize words result =
    case words of
        [] ->
            result

        s :: ss ->
            let
                measuredWidth =
                    HtmlUtil.measureText "sans-self" fontSize s
            in
                if measuredWidth < toFloat containerWidth then
                    case result of
                        [] ->
                            breakWordsHelp containerWidth fontSize ss (s :: result)

                        x :: xs ->
                            let
                                measuredWidth =
                                    HtmlUtil.measureText "sans-self" fontSize (x ++ " " ++ s)
                            in
                                if measuredWidth < toFloat containerWidth then
                                    breakWordsHelp containerWidth fontSize ss ((x ++ " " ++ s) :: xs)
                                else
                                    breakWordsHelp containerWidth fontSize ss (s :: result)
                else
                    let
                        brokenWord =
                            breakWord containerWidth fontSize s
                    in
                        breakWordsHelp containerWidth fontSize ss (brokenWord ++ result)


breakWord : Int -> Float -> String -> List String
breakWord containerWidth fontSize s =
    breakWordHelp containerWidth fontSize s []


breakWordHelp : Int -> Float -> String -> List String -> List String
breakWordHelp containerWidth fontSize s result =
    case cut containerWidth fontSize s of
        ( left, Just right ) ->
            breakWordHelp containerWidth fontSize right (left :: result)

        ( left, Nothing ) ->
            left :: result


cut : Int -> Float -> String -> ( String, Maybe String )
cut containerWidth fontSize s =
    cutHelp containerWidth fontSize s 1


cutHelp : Int -> Float -> String -> Int -> ( String, Maybe String )
cutHelp containerWidth fontSize s i =
    if String.length s < i then
        ( s, Nothing )
    else
        let
            left =
                String.left i s

            measuredWidth =
                HtmlUtil.measureText "sans-self" fontSize left
        in
            if measuredWidth < toFloat containerWidth then
                cutHelp containerWidth fontSize s (i + 1)
            else
                ( String.left (Basics.max 1 (i - 1)) s
                , Just <| String.dropLeft (Basics.max 1 (i - 1)) s
                )
