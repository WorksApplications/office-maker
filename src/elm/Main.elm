import Html exposing (Html)
import StartApp
import Signal exposing (Signal, Address)
import Task
import Effects exposing (Effects)
import Model
import View

app : StartApp.App Model.Model
app = StartApp.start
  { init = Model.init initialSize
  , view = View.view
  , update = Model.update
  , inputs = Model.inputs
  }

main : Signal Html
main = app.html

port tasks : Signal (Task.Task Effects.Never ())
port tasks = app.tasks

port initialSize : (Int, Int)
