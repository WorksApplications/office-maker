module Page.Map.Msg exposing (..)

import Time exposing (Time)
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
import Util.File exposing (File)
import API.Cache as Cache exposing (Cache, UserState)
import Component.FloorProperty as FloorProperty
import Component.Header as Header exposing (..)
import Component.ImageLoader as ImageLoader
import Component.FloorDeleter as FloorDeleter
import Page.Map.URL exposing (URL)
import Page.Map.ContextMenuContext exposing (ContextMenuContext)
import Page.Map.ClipboardOptionsView as ClipboardOptionsView
import CoreType exposing (..)


type alias Id =
    String



{- TODO temporary here for sefe refactoring -}


type ObjectNameInputMsg
    = NoOperation
    | CaretPosition Int
    | InputName ObjectId String Int
    | KeydownOnNameInput (List Person) ( Int, Int )
    | KeyupOnNameInput Int
    | SelectCandidate ObjectId PersonId
    | UnsetPerson ObjectId


type Msg
    = NoOp
    | UrlUpdate (Result String URL)
    | Initialized (Maybe String) Bool UserState User
    | FloorsInfoLoaded Bool (List FloorInfo)
    | FloorLoaded (Maybe Floor)
    | ColorsLoaded ColorPalette
    | PrototypesLoaded (List Prototype)
    | ImageSaved String Int Int
    | RequestSave SaveRequest
    | SaveFloorDebounceMsg Debounce.Msg
    | ObjectsSaved ObjectsChange
    | UnlockSaveFloor
    | FloorSaved FloorBase
    | FloorPublished Floor
    | ClickOnCanvas
    | MouseDownOnCanvas Position
    | MouseUpOnCanvas Position
    | FocusCanvas
    | MouseDownOnObject Bool Bool Id Position
    | MouseUpOnObject Id Position
    | MouseDownOnResizeGrip Id Position
    | StartEditObject Id
    | Ctrl Bool
    | SelectBackgroundColor String
    | SelectColor String
    | SelectShape Object.Shape
    | SelectFontSize Float
    | InputObjectUrl (List ObjectId) String
    | ObjectNameInputMsg ObjectNameInputMsg
    | BeforeContextMenuOnObject Id Msg
    | ContextMenuMsg (ContextMenu.Msg ContextMenuContext)
    | GoToFloor String Bool
    | SelectSamePost String
    | SearchByPost String
    | GotSamePostPeople (List Person)
    | SelectIsland Id
    | SelectSameColor Id
    | WindowSize Size
    | MouseWheel Float Position
    | ChangeMode EditingMode
    | PrototypesMsg Prototypes.Msg
    | ClipboardOptionsMsg ( ClipboardOptionsView.Form, Maybe Size )
    | RegisterPrototype Id
    | FloorPropertyMsg FloorProperty.Msg
    | RotateObjects (List ObjectId)
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
    | GotSearchResult (List SearchResult) (List Person)
    | SelectSearchResult ObjectId FloorId (Maybe PersonId)
    | CloseSearchResult
    | StartDraggingFromMissingPerson String String
    | StartDraggingFromExistingObject Id String (Maybe String) String Time
    | CachePeople (List Person)
    | RequestCandidate Id String
    | SearchCandidateDebounceMsg Debounce.Msg
    | GotCandidateSelection Id (List Person)
    | GotMatchingList (List ( Id, List Person ))
    | UpdatePersonCandidate Id (List Id)
    | PreparePublish
    | GotDiffSource ( Floor, Maybe Floor )
    | CloseDiff
    | ConfirmDiff
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
    | ImageLoaderMsg ImageLoader.Msg
    | GotFileWithDataURL File String
    | FloorDeleterMsg FloorDeleter.Msg
    | FloorDeleted Floor
    | InsertEmoji String
    | ChangeToObjectUrl ObjectId
    | SetTransition Bool
    | Copy
    | Cut
    | Delete
    | MoveSelecedObjectsToward Direction
    | ShiftSelectionByTab
    | ExpandOrShrinkToward Direction
    | Print
    | FlipFloor
    | Error GlobalError
