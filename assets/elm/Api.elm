module Api exposing (getPackage, getFile)

import Data.Package as Package exposing (Package)
import Data.WebData as WebData exposing (WebData)
import Http exposing (Response)
import HttpBuilder exposing (..)

type alias Config a =
    { a | baseUrl: String }

apiUrl : Config a -> String -> String
apiUrl config path =
    config.baseUrl ++ "/" ++ path

packageUrl : Config a -> Package -> String
packageUrl config package =
    (apiUrl config) <|
        "packages/"
        ++ (Package.name package)
        ++ "/"
        ++ (Package.version package)

fileUrl : Config a -> Package -> List String -> String
fileUrl config package path =
    (apiUrl config) <|
        "files/"
        ++ (Package.name package)
        ++ "/"
        ++ (Package.version package)
        ++ "/"
        ++ (String.join "/" path)

getPackage :
    Config a
    -> Package
    -> (List (List String) -> msg)
    -> (Http.Error -> msg)
    -> Cmd msg
getPackage config package tagger errorTagger =
    get (packageUrl config package)
        |> withExpect Http.expectString
        |> send (handleGotPackage tagger errorTagger)

handleGotPackage :
    (List (List String) -> msg)
    -> (Http.Error -> msg)
    -> Result Http.Error String
    -> msg
handleGotPackage tagger errorTagger result =
    case result of
        Ok data ->
            data
                |> String.lines
                |> List.map (String.split "/")
                |> tagger

        Err error ->
            let
                _ =
                    Debug.log "error" error
            in
                errorTagger error

getFile : Config a -> Package -> (WebData String -> msg) -> List String -> Cmd msg
getFile config package tagger path =
    WebData.get (fileUrl config package path) tagger Http.expectString
