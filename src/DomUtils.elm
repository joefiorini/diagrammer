module DomUtils where

import Html (..)
import Native.Custom.Html

import Json.Decode as Json
import Json.Decode (string, Decoder, at, (:=), object5, bool)
import List (head, reverse)

import String (split, toInt)

type alias DragEvent =
  { id: String
  , isStart: Bool
  , isEnd: Bool
  , isDrop: Bool
  , isMulti: Bool
  , startX: Int
  , endX: Int
  , startY: Int
  , endY: Int
  }

type alias MouseSelectionEvent =
  { id: String
  , metaKey: Bool
  , altKey: Bool
  , ctrlKey: Bool
  , shiftKey: Bool
  }

styleProperty = (,)

type alias DnDPort = Signal DragEvent

getTargetId : Json.Decoder String
getTargetId =
  at ["target", "id"] string

getMouseSelectionEvent : Json.Decoder MouseSelectionEvent
getMouseSelectionEvent =
  object5 MouseSelectionEvent
    (at ["target", "id"] string)
    ("metaKey" := bool)
    ("altKey" := bool)
    ("ctrlKey" := bool)
    ("shiftKey" := bool)

stopPropagation = Native.Custom.Html.stopPropagation

extractBoxId : String -> Result String Int
extractBoxId id = toInt << head << reverse <| split "-" id
