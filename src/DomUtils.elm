module DomUtils exposing (..)

import Dom.Types exposing (MouseSelectionEvent)
import Html exposing (..)
import Html.Events exposing (onWithOptions)
import Html.Attributes exposing (class, href, property)
import Html.Events exposing (onClick)
import Json.Decode as Decode exposing (Decoder, at, bool, field, map5, string)
import Json.Encode as Json
import List exposing (head, reverse)
import Msg exposing (..)
import Result exposing (andThen, fromMaybe, map)
import Routes exposing (RouteName)
import String exposing (join, split, toInt)


styleProperty : String -> String -> ( String, String )
styleProperty =
    (,)


getTargetId : Decoder String
getTargetId =
    at [ "target", "id" ] string


getMouseSelectionEvent : Decoder MouseSelectionEvent
getMouseSelectionEvent =
    map5 MouseSelectionEvent
        (at [ "target", "id" ] string)
        (field "metaKey" bool)
        (field "altKey" bool)
        (field "ctrlKey" bool)
        (field "shiftKey" bool)


extractBoxId : String -> Maybe Int
extractBoxId domId =
    -- toInt << head << reverse <| split "-" id
    let
        firstItem =
            split "-" domId |> reverse |> head
    in
        firstItem |> Maybe.andThen (\s -> (toInt s) |> Result.toMaybe)


onLinkClick : Msg -> Attribute Msg
onLinkClick msg =
    let
        options =
            { stopPropagation = False
            , preventDefault = True
            }
    in
        onWithOptions "click" options (Decode.succeed msg)


linkTo : String -> String -> Html Msg
linkTo title url =
    a
        [ href url
        , onLinkClick (NewPage url)
        ]
        [ text title ]


class_ : List String -> Attribute msg
class_ names =
    class <| join " " names


boolProperty : String -> Bool -> Attribute msg
boolProperty key b =
    property key (Json.bool b)
