module Model.User exposing (..) -- where

type alias Id = String

type User =
    Admin String
  | General String
  | Guest

admin : String -> User
admin name =
  Admin name

isAdmin : User -> Bool
isAdmin user =
  case user of
    Admin _ -> True
    _ -> False

isGuest : User -> Bool
isGuest user =
  user == Guest

general : String -> User
general name =
  General name

guest : User
guest = Guest
