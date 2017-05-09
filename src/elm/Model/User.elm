module Model.User exposing (..)

import Model.Person exposing (Person)


type alias Id =
    String


type User
    = Admin Person
    | General Person
    | Guest


isAdmin : User -> Bool
isAdmin user =
    case user of
        Admin _ ->
            True

        _ ->
            False


isGuest : User -> Bool
isGuest user =
    user == Guest


admin : Person -> User
admin person =
    Admin person


general : Person -> User
general person =
    General person


guest : User
guest =
    Guest
