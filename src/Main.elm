module Main exposing (..)

import Board.Controller as Board
import Board.Model exposing (Model)
import Board.Msg
import Box.Msg
import Html exposing (Html, aside, body, div, main_, section, text)
import Html.Attributes exposing (..)
import Interop
import Json.Decode as Decode exposing (Decoder, decodeString, field)
import Json.Encode as Encode
import Keyboard.Extra exposing (Key(..))
import Task
import Dom
import List
import Navigation exposing (Location)
import Partials.About as About
import Partials.Colophon as Colophon
import Partials.Help as Help
import Partials.Releases as Releases
import Partials.Sidebar as Sidebar
import Partials.Header as Header
import Partials.Footer as Footer
import Partials.Toolbar as Toolbar
import Result
import Routes
import Style.Color exposing (Color(..))
import Msg exposing (Msg(..))
import UndoList exposing (UndoList)
import Geometry.Types as Geometry


type alias AppState =
    { currentBoard : Board.Board
    , boardHistory : UndoList Board.Board
    , navigationHistory : List Location
    , currentRoute : Routes.RouteName
    }


main : Program Never AppState Msg
main =
    Navigation.program UrlChange
        { init = startingState
        , view = container
        , update = step
        , subscriptions = subscriptions
        }


parseLocation : Location -> Routes.RouteName
parseLocation location =
    case location.pathname of
        "/" ->
            Routes.Root

        "/about" ->
            Routes.About

        "/colophon" ->
            Routes.Colophon

        "/releases" ->
            Routes.Releases

        "/help" ->
            Routes.Help

        _ ->
            Routes.Root



{-
   Use http://package.elm-lang.org/packages/ohanhi/keyboard-extra/latest to get
   the keys that were pressed in a list, so use those lists for the case clauses
   instead of mousetrap strings; then in the update function, we'll call this
   as part of the (a -> Msg) in Task.perform (might have to use Task.succeed
   with the list of pressed keys to get them into the function)
-}


globalKeyboardShortcuts : List Key -> Msg
globalKeyboardShortcuts keyCommand =
    if Debug.log "keyCommand" keyCommand == [ Tab ] then
        BoardUpdate Board.Msg.SelectNextBox
    else if keyCommand == [ Shift, Tab ] then
        BoardUpdate Board.Msg.SelectPreviousBox
    else if keyCommand == [ CharA ] then
        BoardUpdate Board.Msg.NewBox
    else if keyCommand == [ CharC ] then
        BoardUpdate Board.Msg.ConnectSelections
    else if keyCommand == [ CharX ] then
        BoardUpdate Board.Msg.DisconnectSelections
    else if keyCommand == [ CharD ] then
        BoardUpdate Board.Msg.DeleteSelections
    else if keyCommand == [ Number1 ] then
        BoardUpdate <| Board.Msg.UpdateBoxColor Dark1
    else if keyCommand == [ Number2 ] then
        BoardUpdate <| Board.Msg.UpdateBoxColor Dark2
    else if keyCommand == [ Number3 ] then
        BoardUpdate <| Board.Msg.UpdateBoxColor Dark3
    else
        NoOp



-- "4" ->
--     BoardUpdate <| Board.UpdateBoxColor Dark4
--
-- "shift+1" ->
--     BoardUpdate <| Board.UpdateBoxColor Light1
--
-- "shift+2" ->
--     BoardUpdate <| Board.UpdateBoxColor Light2
--
-- "shift+3" ->
--     BoardUpdate <| Board.UpdateBoxColor Light3
--
-- "shift+4" ->
--     BoardUpdate <| Board.UpdateBoxColor Light4
--
-- "0" ->
--     BoardUpdate <| Board.UpdateBoxColor Black
--
-- "shift+0" ->
--     BoardUpdate <| Board.UpdateBoxColor White
--
-- "shift+=" ->
--     BoardUpdate <| Board.ResizeBox Box.ResizeUpAll
--
-- "-" ->
--     BoardUpdate <| Board.ResizeBox Box.ResizeDownAll
--
-- "ctrl+shift+=" ->
--     BoardUpdate <| Board.ResizeBox Box.ResizeUpNS
--
-- "ctrl+-" ->
--     BoardUpdate <| Board.ResizeBox Box.ResizeDownNS
--
-- "alt+shift+=" ->
--     BoardUpdate <| Board.ResizeBox Box.ResizeUpEW
--
-- "alt+-" ->
--     BoardUpdate <| Board.ResizeBox Box.ResizeDownEW
--
-- "enter" ->
--     BoardUpdate (Board.EditingSelectedBox True)
--
-- "h" ->
--     BoardUpdate <| Board.MoveBox Box.Nudge Box.Left
--
-- "j" ->
--     BoardUpdate <| Board.MoveBox Box.Nudge Box.Down
--
-- "k" ->
--     BoardUpdate <| Board.MoveBox Box.Nudge Box.Up
--
-- "l" ->
--     BoardUpdate <| Board.MoveBox Box.Nudge Box.Right
--
-- "u" ->
--     Undo
--
-- "ctrl+r" ->
--     Redo
--
-- "shift+h" ->
--     BoardUpdate <| Board.MoveBox Box.Push Box.Left
--
-- "shift+j" ->
--     BoardUpdate <| Board.MoveBox Box.Push Box.Down
--
-- "shift+k" ->
--     BoardUpdate <| Board.MoveBox Box.Push Box.Up
--
-- "shift+l" ->
--     BoardUpdate <| Board.MoveBox Box.Push Box.Right
--
-- "alt+shift+h" ->
--     BoardUpdate <| Board.MoveBox Box.Jump Box.Left
--
-- "alt+shift+j" ->
--     BoardUpdate <| Board.MoveBox Box.Jump Box.Down
--
-- "alt+shift+k" ->
--     BoardUpdate <| Board.MoveBox Box.Jump Box.Up
--
-- "alt+shift+l" ->
--     BoardUpdate <| Board.MoveBox Box.Jump Box.Right
-- TODO: Add toggle help here


startingState : Location -> ( AppState, Cmd msg )
startingState location =
    let
        currentRoute =
            parseLocation location
    in
        { currentBoard = Board.startingState
        , boardHistory = UndoList.fresh Board.startingState
        , navigationHistory = [ location ]
        , currentRoute = currentRoute
        }
            ! []


encodeAppState : AppState -> Encode.Value
encodeAppState state =
    Encode.object
        [ ( "currentBoard", Board.Model.encode state.currentBoard )
        ]


mkState : Model -> AppState
mkState board =
    { currentBoard = board
    , boardHistory = UndoList.fresh Board.startingState
    , currentRoute = Routes.Root
    , navigationHistory = []
    }


decodeAppState : Decoder AppState
decodeAppState =
    Decode.map mkState
        (field "currentBoard" Board.Model.decode)


extractAppState : Result.Result String AppState -> AppState
extractAppState result =
    case result of
        Result.Ok state ->
            state

        Result.Err s ->
            Debug.crash s


subscriptions : model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Interop.dragstart (\e -> Board.moveBoxAction e |> BoardUpdate)
        , Interop.drop (\e -> Board.moveBoxAction e |> BoardUpdate)
        , Interop.loadedState LoadedState
        ]



-- TODO: Add to main keyboard map
-- toggleHelp =
--     Signal.map
--         (\k ->
--             case k of
--                 "shift+/" ->
--                     Routes.Help
--
--                 "w" ->
--                     Routes.Root
--
--                 _ ->
--                     Routes.Root
--         )
--         Mousetrap.keydown


entersEditMode : Msg -> Bool
entersEditMode update =
    case update of
        BoardUpdate a ->
            Board.entersEditMode a

        otherwise ->
            False


initTimeMachine : AppState -> AppState
initTimeMachine appState =
    let
        history =
            UndoList.fresh appState.currentBoard
    in
        { appState | boardHistory = history }



-- restoreStateFromHistory : TimeMachine.History ->


step : Msg -> AppState -> ( AppState, Cmd Msg )
step update state =
    case Debug.log "update" update of
        LoadedState deserializedState ->
            deserializedState
                |> decodeString decodeAppState
                |> extractAppState
                |> initTimeMachine
                |> flip (!) [ Cmd.none ]

        NewPage path ->
            state ! [ Navigation.newUrl path ]

        UrlChange location ->
            let
                newRoute =
                    parseLocation location
            in
                { state | currentRoute = newRoute, navigationHistory = location :: state.navigationHistory } ! []

        BoardUpdate u ->
            let
                recordedHistory =
                    UndoList.mapPresent (Board.step u) state.boardHistory

                history_ =
                    case u of
                        Board.Msg.NewBox ->
                            recordedHistory

                        Board.Msg.MoveBox _ _ ->
                            recordedHistory

                        Board.Msg.UpdateBoxColor _ ->
                            recordedHistory

                        Board.Msg.DeleteSelections ->
                            recordedHistory

                        Board.Msg.ConnectSelections ->
                            recordedHistory

                        Board.Msg.DisconnectSelections ->
                            recordedHistory

                        Board.Msg.Drop _ _ ->
                            recordedHistory

                        Board.Msg.ResizeBox _ ->
                            recordedHistory

                        Board.Msg.BoxAction (Box.Msg.EditingBox _ _) ->
                            recordedHistory

                        _ ->
                            state.boardHistory

                cmd =
                    case u of
                        Board.Msg.EditingBox boxKey toggle ->
                            Board.toSelector boxKey |> Dom.focus |> (Task.attempt (\_ -> NoOp))

                        _ ->
                            Cmd.none
            in
                { state
                    | currentBoard = (Board.step u history_.present)
                    , boardHistory = Debug.log "new history" history_
                }
                    ! [ cmd ]

        ToolbarUpdate u ->
            let
                updatedBoard =
                    Board.step Board.Msg.ClearBoard state.currentBoard
            in
                { state | currentBoard = updatedBoard } ! []

        Undo ->
            let
                history =
                    UndoList.undo state.boardHistory
            in
                history.present
                    |> (\board ->
                            { state
                                | currentBoard = board
                                , boardHistory = history
                            }
                       )
                    |> flip (!) []

        Redo ->
            let
                history =
                    UndoList.redo state.boardHistory
            in
                history.present
                    |> (\board ->
                            { state
                                | currentBoard = board
                                , boardHistory = history
                            }
                       )
                    |> flip (!) []

        SerializeState ->
            ( state
            , state
                |> (Encode.encode 0)
                << encodeAppState
                |> Interop.serializeState
            )

        _ ->
            state ! []


container : AppState -> Html Msg
container state =
    let
        sidebar h =
            Sidebar.view h

        offsetHeight =
            -- TODO: Don't hard code this. get the actual height, if needed?
            1024 - 52

        board =
            Board.view BoardUpdate state.currentBoard offsetHeight

        ( sidebar_, extraClass, sidebarHeight ) =
            case state.currentRoute of
                Routes.About ->
                    ( sidebar <| About.view, "l-board--compressed", offsetHeight )

                Routes.Colophon ->
                    ( sidebar <| Colophon.view, "l-board--compressed", offsetHeight )

                Routes.Help ->
                    ( sidebar <| Help.view, "l-board--compressed", offsetHeight )

                Routes.Releases ->
                    ( sidebar <| Releases.view, "l-board--compressed", offsetHeight )

                _ ->
                    ( text "", "", 0 )
    in
        section []
            [ Header.view
            , Toolbar.view ToolbarUpdate
            , main_
                [ class "l-container" ]
                [ section
                    [ classList [ ( "l-board", True ), ( extraClass, extraClass /= "" ) ]
                    ]
                    [ board ]
                , section
                    [ class "l-content"
                    , style
                        [ ( "height", (Geometry.toPx sidebarHeight) )
                        ]
                    ]
                    [ sidebar_
                    ]
                ]
            , section
                [ class "l-container" ]
                [ Footer.view ]
            ]
