module Model.User where

type alias Id = String

type User =
    Admin String
  | General String
  | Guest


admin : String -> User
admin name =
  Admin name

general : String -> User
general name =
  General name

guest : User
guest = Guest
