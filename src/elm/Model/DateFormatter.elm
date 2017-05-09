module Model.DateFormatter exposing (formatDate, formatDateOrTime)

import Date exposing (..)
import Model.I18n exposing (Language(..))


monthToInt : Month -> Int
monthToInt month =
    case month of
        Jan ->
            1

        Feb ->
            2

        Mar ->
            3

        Apr ->
            4

        May ->
            5

        Jun ->
            6

        Jul ->
            7

        Aug ->
            8

        Sep ->
            9

        Oct ->
            10

        Nov ->
            11

        Dec ->
            12


sameDay : Date -> Date -> Bool
sameDay d1 d2 =
    year d1
        == year d2
        && month d1
        == month d2
        && day d1
        == day d2


am : Date -> Bool
am date =
    if hour date < 12 then
        True
    else
        False


pm : Date -> Bool
pm =
    not << am


hourOfAmPm : Int -> Int
hourOfAmPm hour =
    if hour > 12 then
        hour - 12
    else
        hour


ampm : Date -> String
ampm date =
    toString (hourOfAmPm (hour date))
        ++ ":"
        ++ fillZero2 (toString (minute date))
        ++ " "
        ++ (if am date then
                "a.m."
            else
                "p.m."
           )


formatTime : Language -> Date -> String
formatTime lang date =
    case lang of
        JA ->
            fillZero2 (toString (hour date))
                ++ ":"
                ++ fillZero2 (toString (minute date))

        EN ->
            ampm date


fillZero2 : String -> String
fillZero2 s =
    String.right 2 ("0" ++ s)


formatDate : Language -> Date -> String
formatDate lang date =
    case lang of
        JA ->
            toString (Date.year date)
                ++ "/"
                ++ toString (monthToInt <| Date.month date)
                ++ "/"
                ++ toString (Date.day date)

        EN ->
            toString (monthToInt <| Date.month date)
                ++ "/"
                ++ toString (Date.day date)
                ++ "/"
                ++ toString (Date.year date)


formatDateOrTime : Language -> Date -> Date -> String
formatDateOrTime lang now date =
    if sameDay now date then
        formatTime lang date
    else
        formatDate lang date
