module Api exposing (getPackage, getFile)

import Data.WebData as WebData exposing (WebData)
import Http exposing (Response)
import HttpBuilder exposing (..)

type alias Config a =
    { a | baseUrl: String }

type alias PackageVersion =
    ( String, String )

apiUrl : Config a -> String -> String
apiUrl config path =
    config.baseUrl ++ "/" ++ path

packageUrl : Config a -> PackageVersion -> String
packageUrl config ( package, version ) =
    (apiUrl config) <| "packages/" ++ package ++ "/" ++ version

fileUrl : Config a -> PackageVersion -> List String -> String
fileUrl config ( package, version ) path =
    (apiUrl config) <|
        "files/"
            ++ package
            ++ "/"
            ++ version
            ++ "/"
            ++ (String.join "/" path)

getPackage :
    Config a
    -> PackageVersion
    -> (List (List String) -> msg)
    -> (Http.Error -> msg)
    -> Cmd msg
getPackage config packageVersion tagger errorTagger =
    get (packageUrl config packageVersion)
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

getFile : Config a -> PackageVersion -> (WebData String -> msg) -> List String -> Cmd msg
getFile config packageVersion tagger path =
    WebData.get (fileUrl config packageVersion path) tagger Http.expectString
