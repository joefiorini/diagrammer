module DomUtils where

import Html (..)
import Native.Custom.Html

import String (split, toInt)

type DragEvent =
  { id: String
  , startX: Int
  , endX: Int
  , startY: Int
  , endY: Int
  }

type DropPort = Signal DragEvent

getTargetId : Get String
getTargetId = Native.Custom.Html.getTargetId

getMouseSelectionEvent = Native.Custom.Html.getMouseSelectionEvent

extractBoxId : String -> Maybe Int
extractBoxId id = toInt << last <| split "-" id
