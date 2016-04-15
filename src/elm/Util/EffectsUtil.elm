module Util.EffectsUtil where

import Effects exposing (..)
import Task exposing (..)

fromTask : (err -> b) -> (a -> b) -> Task.Task err a -> Effects b
fromTask g f task =
  Effects.task <|
    task
      `Task.andThen` (\a -> Task.succeed (f a))
      `Task.onError` (\e -> Task.succeed (g e))

fromTaskWithNoError : (a -> b) -> Task.Task Never a -> Effects b
fromTaskWithNoError f task =
  Effects.task <|
    Task.map f task
