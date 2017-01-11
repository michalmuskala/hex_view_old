module Api exposing (getPackage)

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
