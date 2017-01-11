module Data.WebData exposing
    ( WebData(..)
    , get
    , map
    , fromResult
    , runUnlessLoaded
    )

import Http exposing (Header, Expect, Error, Request, Body)

type WebData a
    = NotAsked
    | Loading
    | Failure Http.Error
    | Success a


map : (a -> b) -> WebData a -> WebData b
map mapper data =
    case data of
        Success value ->
            Success (mapper value)
        Failure error ->
            Failure error
        NotAsked ->
            NotAsked
        Loading ->
            Loading

fromResult : Result Error success -> WebData success
fromResult result =
    case result of
        Err e ->
            Failure e

        Ok x ->
            Success x

runUnlessLoaded : WebData a -> Cmd msg -> Cmd msg
runUnlessLoaded current command =
    case current of
        NotAsked ->
            command
        Loading ->
            command
        Failure _ ->
            command
        Success _ ->
            Cmd.none

toCmd : (WebData success -> msg) -> Request success -> Cmd msg
toCmd tagger =
    Http.send (tagger << fromResult)

request :
    String
    -> List Header
    -> String
    -> Expect success
    -> Body
    -> Request success
request method headers url successDecoder body =
    Http.request
        { method = method
        , headers = headers
        , url = url
        , body = body
        , expect = successDecoder
        , timeout = Nothing
        , withCredentials = False
        }

getRequest : List Header -> String -> Expect success -> Request success
getRequest headers url decoder =
    request "GET" headers url decoder Http.emptyBody

get : String -> (WebData success -> msg) -> Expect success -> Cmd msg
get url tagger decoder =
    getRequest [] url decoder
        |> toCmd tagger
