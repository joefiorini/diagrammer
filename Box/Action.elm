module Box.Action where

import Box.State (BoxKey, Box)

import DomUtils (DragEvent)

data Action = Move DragEvent
            | Editing Bool
            | Selected
            | NoOp
            | Update String

