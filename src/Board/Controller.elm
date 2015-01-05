module Board.Controller where

import Keyboard
import Debug

import Signal
import Signal (Channel, (<~))

import Html (..)
import Html.Events (on)
import Html.Attributes (id, style, property)

import Board.Model

import Box.Controller as Box

import Connection.Controller as Connection
import Connection.Model

import DomUtils (getTargetId, extractBoxId, getMouseSelectionEvent, styleProperty, DragEvent, DnDPort)

import Html (Html)

import LocalChannel as LC

import String (split, toInt)
import List
import List ((::))

import Result

import Native.Custom.Html
import Geometry.Types as Geometry

type alias Board = Board.Model.Model

type Update = NoOp |
  BoxAction Box.Update |
  RequestedAdd |
  UpdateBox Box.Model String |
  NewBox |
  MoveBox Box.BoxKey DragEvent |
  DeselectBoxes |
  EditingBox Box.BoxKey Bool |
  EditingSelectedBox Bool |
  SelectBox Box.BoxKey |
  SelectBoxMulti Box.BoxKey |
  CancelEditingBox Box.BoxKey |
  ConnectSelections |
  ReconnectSelections |
  DeleteSelections |
  DraggingBox Box.BoxKey |
  Drop DragEvent

view channel model height =
  div [ style
      [ styleProperty "position" "relative"
      , styleProperty "width" "100%"
      , styleProperty "height" <| Geometry.toPx height
      , styleProperty "border" "solid thin blue"
      , styleProperty "overflow" "hidden"
      ]
      , id "container"
      , on "dblclick" getTargetId (\v -> LC.send channel <| buildEditingAction v)
      , on "mousedown" getMouseSelectionEvent (\v -> LC.send channel <| buildSelectAction v)
    ] <| widgets channel model

entersEditMode update =
  Debug.log "entersEditMode" <| case update of
    (EditingBox _ toggle) ->
      toggle
    (EditingSelectedBox toggle) ->
      toggle
    (BoxAction a) ->
      Box.entersEditMode a
    otherwise ->
      False

encode = Board.Model.encode
decode = Board.Model.decode

renderConnections : List Connection.Model.Model -> List Html
renderConnections = List.map Connection.renderConnection

buildSelectAction event = let boxIdM = extractBoxId event.id in
                    case boxIdM of
                      Result.Ok key ->
                        if | event.metaKey -> SelectBoxMulti key
                           | otherwise -> SelectBox key
                      Result.Err s -> Debug.log "deselect" DeselectBoxes

buildEditingAction : String -> Update
buildEditingAction id = let boxIdM = extractBoxId id in
                   case boxIdM of
                     Result.Ok key ->
                       EditingBox key True
                     Result.Err s -> NoOp

widgets : LC.LocalChannel Update -> Board -> List Html
widgets channel board =
  let boxChannel = LC.localize (\a -> Debug.log "BoxAction" <| BoxAction a) channel
  in
  List.concatMap identity
    [ (List.map (Box.view boxChannel) board.boxes)
    , (renderConnections board.connections)
    ]

actions : Channel Update
actions = Signal.channel NoOp

checkFocus =
    let needsFocus act =
            case act of
              EditingBox key bool -> bool
              _ -> False

        toSelector (EditingBox id _) = ("#box-" ++ toString id ++ "-label")
    in
        toSelector <~ Signal.keepIf needsFocus (EditingBox 0 True) (Signal.subscribe actions)

keyboardRequest keyCode = case keyCode of
  65 -> NewBox
  67 -> ConnectSelections
  68 -> DeleteSelections
  13 -> EditingSelectedBox True
  _ -> NoOp

moveBoxAction : DragEvent -> Update
moveBoxAction event = let boxKeyM = extractBoxId event.id in
    case boxKeyM of
      Ok key ->
       if | event.isStart -> DraggingBox key
          | otherwise -> MoveBox key event
      Err s -> NoOp

startingState =
  { boxes = []
  , connections = []
  , nextIdentifier = 1
  }

isEditing = List.any (.isEditing)

updateStateSelections box state =
  let updateBox lastBox _ = Box.step (Box.SetSelected <| lastBox.selectedIndex + 1) box in
  { state | boxes <- List.foldl updateBox state.boxes }

contains obj = List.any (\b -> b == obj)
containsEither obj1 obj2 = List.any (\b -> b == obj1 || b == obj2)

sortLeftToRight : List Box.Model -> List Box.Model
sortLeftToRight boxes = List.sortBy (snd << (.position)) <| List.sortBy (fst << (.position)) boxes

boxForKey : Box.BoxKey -> List Box.Model -> Box.Model
boxForKey key boxes = List.head (List.filter (\b -> b.key == key) boxes)

makeBox : Box.BoxKey -> Box.Model
makeBox identifier =
  { position = (0,0)
  , size = (100, 50)
  , label = "New Box"
  , originalLabel = "New Box"
  , key = identifier
  , isEditing = False
  , isDragging = False
  , selectedIndex = 1
  , borderSize = 2
  }

replaceBox : List Box.Model -> Box.Model -> List Box.Model
replaceBox boxes withBox = List.map (\box ->
      if box.key == withBox.key then withBox else box) boxes

step : Update -> Board -> Board
step update state =
  let updateBoxInState update box iterator = (if iterator.key == box.key then Box.step update iterator else iterator)
      updateSelectedBoxes update iterator = (if iterator.selectedIndex > -1 then Box.step update iterator else iterator)
      performActionOnAllBoxes update = (Box.step update)
      nextSelectedIndex boxes = List.foldl (\last index -> if index > last then index + 1 else last + 1) 0 <| List.map (.selectedIndex) boxes
      selectedBoxes boxes = List.sortBy (.selectedIndex)
                        <| List.filter (\b -> b.selectedIndex > -1) boxes
      deselectBoxes = List.map (\box -> { box | selectedIndex <- -1 }) in
    case Debug.log "Performing update" update of
      NewBox ->
        if | isEditing state.boxes -> state
           | True ->
            let newBox = makeBox state.nextIdentifier in
              Debug.log "newBox" { state | boxes <- newBox :: (deselectBoxes state.boxes)
                                         , nextIdentifier <- state.nextIdentifier + 1 }
      BoxAction (Box.CancelEditingBox box) ->
        let box' = Box.step Box.CancelEditing box
            boxes' = replaceBox state.boxes box'
        in
          Debug.log "Canceling edit" { state | boxes <- deselectBoxes boxes' }
      DeselectBoxes ->
        let cancelEditing = List.map (Box.step Box.CancelEditing)
            updateBoxes = cancelEditing >> deselectBoxes in
          { state | boxes <- updateBoxes state.boxes }
      SelectBoxMulti id ->
        let box = boxForKey id state.boxes
            updateBoxes boxes = List.map (updateBoxInState (Box.SetSelected <| nextSelectedIndex boxes) box) boxes in
          Debug.log "adding box to selection" { state | boxes <- updateBoxes state.boxes }

      DraggingBox id ->
        let box = boxForKey id state.boxes
            selectedBox boxes = List.map (updateBoxInState (Box.SetSelected <| nextSelectedIndex boxes) box) boxes
            draggingBox = List.map (updateSelectedBoxes Box.Dragging)
            updateBoxes = selectedBox >> draggingBox in
            Debug.log "started dragging" { state | boxes <- updateBoxes state.boxes }

      SelectBox id ->
        let box = boxForKey id state.boxes
            selectedBox boxes = List.map (updateBoxInState (Box.SetSelected <| nextSelectedIndex boxes) box) boxes
            updateBoxes = deselectBoxes >> selectedBox in
          if | box.selectedIndex > -1 -> state
             | otherwise ->
          Debug.log "selecting box" { state | boxes <- updateBoxes state.boxes }
      EditingBox boxKey toggle ->
        let box = boxForKey boxKey state.boxes
            box' = Box.step (Box.Editing toggle) box
            boxes' = replaceBox state.boxes box'
        in
          Debug.log "Canceling edit" { state | boxes <- boxes' }

      BoxAction (Box.EditingBox box toggle) ->
        let box' = Box.step (Box.Editing toggle) box
        in
          Debug.log "editing box" { state | boxes <- replaceBox state.boxes <| box' }
      EditingSelectedBox toggle ->
          let selectedBoxes = List.filter (\b -> b.selectedIndex /= -1) state.boxes in
            if | List.length selectedBoxes == 1 ->
              { state | boxes <- replaceBox state.boxes <| Box.step (Box.Editing toggle)
                                                        <| List.head selectedBoxes }
               | otherwise ->
              state
      BoxAction (Box.UpdateBox box label) ->
        Debug.log "Box.UpdateBox" { state | boxes <- replaceBox state.boxes <| Box.step (Box.Update label) box }
      MoveBox key event ->
        let draggingBox = List.map (updateSelectedBoxes Box.Dragging)
            moveAllSelectedBoxes boxes = List.map (updateSelectedBoxes (Box.Move event)) boxes
            updateBoxes = moveAllSelectedBoxes >> draggingBox
        in
          Debug.log "moved box"
            step ReconnectSelections { state | boxes <- updateBoxes state.boxes }
      ReconnectSelections ->
        { state | connections <- Connection.boxMap
                                  Connection.connectBoxes
                                  state.boxes state.connections }
      ConnectSelections ->
        if | List.length (selectedBoxes state.boxes) < 2 -> state
           | otherwise ->
             Debug.log "Connecting Selections"
             { state | connections <- Connection.buildConnections state.connections
                                          <| Debug.log "Selected Boxes" <| selectedBoxes state.boxes }

      DeleteSelections ->
        let isSelected boxKey =
          List.length (Box.filterKey Box.isSelected boxKey state.boxes)
            == 0
        in
        Debug.log "Deleting Selections"
          { state | boxes <- List.filter Box.isSelected state.boxes,
                    connections <- List.filter
                      (\c ->
                        (isSelected c.startBox) &&
                        (isSelected c.endBox))
                      state.connections }
      _ -> state
      NoOp -> Debug.log "NoOp" state
