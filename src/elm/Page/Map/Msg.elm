module Page.Map.Msg exposing (..)

import Time exposing (Time)
import Mouse exposing (Position)
import Debounce exposing (Debounce)
import ContextMenu exposing (ContextMenu)

import Model.Mode as Mode exposing (Mode(..), EditingMode(..))
import Model.User as User exposing (User)
import Model.Person as Person exposing (Person)
import Model.Object as Object exposing (..)
import Model.ObjectsChange exposing (ObjectsChange)
import Model.Prototype exposing (Prototype)
import Model.Prototypes as Prototypes exposing (Prototypes)
import Model.Floor as Floor exposing (Floor, FloorBase)
import Model.FloorInfo as FloorInfo exposing (FloorInfo)
import Model.Errors as Errors exposing (GlobalError(..))
import Model.I18n as I18n exposing (Language(..))
import Model.SearchResult as SearchResult exposing (SearchResult)
import Model.SaveRequest as SaveRequest exposing (SaveRequest(..))
import Model.ColorPalette as ColorPalette exposing (ColorPalette)

import API.Cache as Cache exposing (Cache, UserState)

import Component.FloorProperty as FloorProperty
import Component.Header as Header exposing (..)
import Component.ObjectNameInput as ObjectNameInput

import Page.Map.URL exposing (URL)
import Page.Map.ContextMenuContext exposing (ContextMenuContext)


type alias Size =
  { width : Int
  , height : Int
  }


type Msg
  = NoOp
  | UrlUpdate (Result String URL)
  | Initialized (Maybe String) Bool UserState User
  | FloorsInfoLoaded (List FloorInfo)
  | FloorLoaded (Maybe Floor)
  | ColorsLoaded ColorPalette
  | PrototypesLoaded (List Prototype)
  | ImageSaved String Int Int
  | RequestSave SaveRequest
  | SaveFloorDebounceMsg Debounce.Msg
  | ObjectsSaved ObjectsChange
  | FloorSaved FloorBase
  | FloorPublished Floor
  | FloorDeleted Floor
  | ClickOnCanvas
  | MouseUpOnCanvas
  | MouseDownOnCanvas Position
  | MouseDownOnObject Id Position
  | MouseUpOnObject Id
  | MouseDownOnResizeGrip Id Position
  | StartEditObject Id
  | KeyCodeMsg Bool Int
  | SelectBackgroundColor String
  | SelectColor String
  | SelectShape Object.Shape
  | SelectFontSize Float
  | ObjectNameInputMsg ObjectNameInput.Msg
  | BeforeContextMenuOnObject Id Msg
  | ContextMenuMsg (ContextMenu.Msg ContextMenuContext)
  | GoToFloor (Maybe (String, Bool))
  | SelectSamePost String
  | SearchByPost String
  | GotSamePostPeople (List Person)
  | SelectIsland Id
  | SelectSameColor Id
  | WindowSize Size
  | MouseWheel Float Position
  | ChangeMode EditingMode
  | ScaleEnd
  | PrototypesMsg Prototypes.Msg
  | RegisterPrototype Id
  | FloorPropertyMsg FloorProperty.Msg
  | Rotate Id
  | FirstNameOnly (List Id)
  | RemoveSpaces (List Id)
  | HeaderMsg Header.Msg
  | SignIn
  | SignOut
  | ToggleEditing
  | TogglePrintView
  | SelectLang Language
  | UpdateSearchQuery String
  | SubmitSearch
  | GotSearchResult (List SearchResult)
  | SelectSearchResult SearchResult
  | StartDraggingFromMissingPerson String String
  | StartDraggingFromExistingObject Id String (Maybe String) String Time
  | RegisterPeople (List Person)
  | RequestCandidate Id String
  | SearchCandidateDebounceMsg Debounce.Msg
  | GotCandidateSelection Id (List Person)
  | GotMatchingList (List (Id, List Person))
  | UpdatePersonCandidate Id (List Id)
  | PreparePublish
  | GotDiffSource (Floor, Maybe Floor)
  | CloseDiff
  | ConfirmDiff
  | HideSearchResult
  | ClosePopup
  | ShowDetailForObject Id
  | CreateNewFloor
  | CopyFloor FloorId Bool
  | EmulateClick Id Bool Time
  | TokenRemoved
  | Undo
  | Redo
  | Focused
  | PasteFromClipboard String
  | SyncFloor
  | MouseMove Position
  | MouseUp
  | Error GlobalError
