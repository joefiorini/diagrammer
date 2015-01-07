module Main where
import Graphics.Element (Element)
import Html
import Html (Html, toElement, div, main', body, text, section, aside)
import Html.Attributes (class)
import Board.Controller as Board
import Board.Controller (checkFocus)
import Box.Controller as Box
import DomUtils (DragEvent, class', linkTo)
import Mousetrap
import LocalChannel as LC
import Partials.Header as Header
import Partials.Footer as Footer
import Native.App as App
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode ((:=))
import Signal
import Result
import Routes
import Signal (Signal, (<~), (~))
import Keyboard
import Window
import Debug
import Style.Color (Color(..))

port drop : Signal DragEvent
port dragstart : Signal DragEvent
port dragend : Signal DragEvent

port focus : Signal String
port focus = checkFocus

port globalKeyDown : Signal Int

type alias AppState =
  { currentBoard        : Board.Board
  }

main : Signal Element
main = (\s r (w,h) -> toElement w h  <| container s r h)
        <~ state
         ~ routeHandler
         ~ Window.dimensions

globalKeyboardShortcuts : String -> Update
globalKeyboardShortcuts keyCommand =
  case Debug.log "keyCommand" keyCommand of
    "tab"       -> BoardUpdate Board.SelectNextBox
    "shift+tab" -> BoardUpdate Board.SelectPreviousBox
    "a"     -> BoardUpdate Board.NewBox
    "c"     -> BoardUpdate Board.ConnectSelections
    "d"     -> BoardUpdate Board.DeleteSelections
    "1"     -> BoardUpdate <| Board.UpdateBoxColor Dark1
    "2"     -> BoardUpdate <| Board.UpdateBoxColor Dark2
    "3"     -> BoardUpdate <| Board.UpdateBoxColor Dark3
    "4"     -> BoardUpdate <| Board.UpdateBoxColor Dark4
    "shift+1"     -> BoardUpdate <| Board.UpdateBoxColor Light1
    "shift+2"     -> BoardUpdate <| Board.UpdateBoxColor Light2
    "shift+3"     -> BoardUpdate <| Board.UpdateBoxColor Light3
    "shift+4"     -> BoardUpdate <| Board.UpdateBoxColor Light4
    "0"     -> BoardUpdate <| Board.UpdateBoxColor Black
    "shift+0"     -> BoardUpdate <| Board.UpdateBoxColor White
    "shift+="       -> BoardUpdate <| Board.ResizeBox Box.ResizeUpAll
    "-"             -> BoardUpdate <| Board.ResizeBox Box.ResizeDownAll
    "ctrl+shift+="  -> BoardUpdate <| Board.ResizeBox Box.ResizeUpNS
    "ctrl+-"        -> BoardUpdate <| Board.ResizeBox Box.ResizeDownNS
    "alt+shift+="   -> BoardUpdate <| Board.ResizeBox Box.ResizeUpEW
    "alt+-"         -> BoardUpdate <| Board.ResizeBox Box.ResizeDownEW
    "enter" -> BoardUpdate (Board.EditingSelectedBox True)
    "h"     -> BoardUpdate <| Board.MoveBox Box.Nudge Box.Left
    "j"     -> BoardUpdate <| Board.MoveBox Box.Nudge Box.Down
    "k"     -> BoardUpdate <| Board.MoveBox Box.Nudge Box.Up
    "l"     -> BoardUpdate <| Board.MoveBox Box.Nudge Box.Right
    "shift+h"       -> BoardUpdate <| Board.MoveBox Box.Push Box.Left
    "shift+j"       -> BoardUpdate <| Board.MoveBox Box.Push Box.Down
    "shift+k"       -> BoardUpdate <| Board.MoveBox Box.Push Box.Up
    "shift+l"       -> BoardUpdate <| Board.MoveBox Box.Push Box.Right
    "alt+shift+h"       -> BoardUpdate <| Board.MoveBox Box.Jump Box.Left
    "alt+shift+j"       -> BoardUpdate <| Board.MoveBox Box.Jump Box.Down
    "alt+shift+k"       -> BoardUpdate <| Board.MoveBox Box.Jump Box.Up
    "alt+shift+l"       -> BoardUpdate <| Board.MoveBox Box.Jump Box.Right
    _       -> NoOp


startingState : AppState
startingState =
  { currentBoard = Board.startingState
  }

routesMap routeName =
  let url =
    case routeName of
      Routes.Root -> "/"
      Routes.About -> "/about"
      Routes.Colophon -> "/colophon"
      Routes.Help -> "/help"
  in
     (url, routeName)

encodeAppState : AppState -> Encode.Value
encodeAppState state =
  Encode.object
    [ ("currentBoard", Board.encode state.currentBoard)
    ]

decodeAppState : Decode.Decoder AppState
decodeAppState =
  Decode.object1 AppState
    ("currentBoard" := Board.decode)

extractAppState : Result.Result String AppState -> AppState
extractAppState result =
  case result of
    Result.Ok state -> state
    Result.Err s -> Debug.crash s

deserializedState : Signal Update
deserializedState =
  let deserializeAppState = Decode.decodeString decodeAppState
      loadedState' = Signal.keepIf ((/=) "")
        (Encode.encode 0 <| encodeAppState startingState) loadedState
  in
    (HydrateAppState << extractAppState << deserializeAppState) <~ loadedState'

port loadedState : Signal String

port serializeState : Signal String
port serializeState =
  let serializeAppState = (Encode.encode 0) << encodeAppState
  in
    serializeAppState <~ state


-- port transitionToRoute : Signal Routes.Url
-- port transitionToRoute =
--   Routes.sendToPort routeHandler

routeHandler =
  Routes.map routesMap
    <| Signal.subscribe routeChannel

type Update = NoOp
            | HydrateAppState AppState
            | BoardUpdate Board.Update

updates : Signal.Channel Update
updates = Signal.channel NoOp

routeChannel : Signal.Channel Routes.RouteName
routeChannel = Signal.channel Routes.Root

userInput = Signal.mergeMany [drop, dragstart, dragend]

state : Signal.Signal AppState
state =
  Signal.foldp step startingState
    (Signal.mergeMany
      [ Signal.subscribe updates
      , deserializedState
      , Signal.map globalKeyboardShortcuts Mousetrap.keydown
      , convertDragOperation <~ Signal.mergeMany [drop, dragstart]
      ])

entersEditMode update =
  case update of
    BoardUpdate a ->
      Board.entersEditMode a
    otherwise ->
      False

inEditingMode : Signal Bool
inEditingMode = Signal.map entersEditMode (Signal.subscribe updates)

convertDragOperation dragE =
  BoardUpdate <| Board.moveBoxAction dragE

step : Update -> AppState -> AppState
step update state =
  case Debug.log "update" update of
    HydrateAppState state' -> Debug.log "Updated State" state'
    BoardUpdate u ->
      let updatedBoard = Board.step u state.currentBoard
      in
      { state | currentBoard <- updatedBoard }
    _ -> state

container : AppState -> Routes.Route -> Int -> Html.Html
container state (url,route) screenHeight =
  let headerChannel = LC.create identity routeChannel
      boardChannel = LC.create BoardUpdate updates
      board = Board.view boardChannel state.currentBoard (screenHeight - 36)
      (sidebar,extraClass) =
        case route of
          Routes.About ->
            ( text "About Diagrammer" , "l-board--compressed" )
          Routes.Colophon ->
            ( text "What's in it", "l-board--compressed" )
          Routes.Help ->
            ( text "Keyboard Shortcuts", "l-board--compressed" )
          _ -> ( text "" , "")

  in
    div []
      [ Header.view headerChannel
      , main'
        [class "l-container"]
        [ section
          [ class' ["l-board", extraClass]
          ]
          [ board ]
        , section
            [class "l-content"]
            [ aside
              [ class "sidebar" ]
              [ linkTo "x" "#" (Signal.send routeChannel Routes.Root)
              , sidebar ]
            ]
        ]
      , section
        [ class "l-container" ]
        [ Footer.view ]
      ]
