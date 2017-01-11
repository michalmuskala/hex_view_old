module Data.WebData exposing
    ( WebData(..)
    , fromResult
    )

import Http exposing (Header, Expect, Error, Request, Body)

type WebData a
    = NotAsked
    | Loading
    | Failure Http.Error
    | Success a

fromResult : Result Error success -> WebData success
fromResult result =
    case result of
        Err e ->
            Failure e

        Ok x ->
            Success x

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
