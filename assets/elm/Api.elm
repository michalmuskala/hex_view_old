module Api exposing (getPackage, getFile)

import Http exposing (Response)
import HttpBuilder exposing (..)


type alias PackageVersion =
    ( String, String )


apiBase : String
apiBase =
    "http://localhost:4000/api"


apiUrl : String -> String
apiUrl path =
    apiBase ++ "/" ++ path


packageUrl : PackageVersion -> String
packageUrl ( package, version ) =
    apiUrl <| "packages/" ++ package ++ "/" ++ version


fileUrl : PackageVersion -> List String -> String
fileUrl ( package, version ) path =
    apiUrl <|
        "files/"
            ++ package
            ++ "/"
            ++ version
            ++ "/"
            ++ (String.join "/" path)


getPackage :
    PackageVersion
    -> (List (List String) -> msg)
    -> (Http.Error -> msg)
    -> Cmd msg
getPackage packageVersion tagger errorTagger =
    get (packageUrl packageVersion)
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


getFile :
    PackageVersion
    -> List String
    -> (String -> msg)
    -> (Http.Error -> msg)
    -> Cmd msg
getFile packageVersion path tagger errorTagger =
    get (fileUrl packageVersion path)
        |> withExpect Http.expectString
        |> send (handleGotFile tagger errorTagger)


handleGotFile :
    (String -> msg)
    -> (Http.Error -> msg)
    -> Result Http.Error String
    -> msg
handleGotFile tagger errorTagger result =
    case result of
        Ok data ->
            tagger data

        Err error ->
            let
                _ =
                    Debug.log "error" error
            in
                errorTagger error
