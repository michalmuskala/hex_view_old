module Pages.PackageView.Model exposing
    ( Model
    , Flags
    , Files
    , init
    )

import Data.FileTreeZipper as FileTreeZipper exposing (FileTreeZipper)
import Data.WebData as WebData exposing (WebData)

type alias Files = FileTreeZipper String (WebData String)

type alias Flags =
    { baseUrl : String
    , packageName : String
    , packageVersion : String
    }

type alias Model a =
    { a |
      files : Files
    , baseUrl : String
    , packageName : String
    , packageVersion : String
    }


init : Flags -> Model {}
init flags =
    let
        paths = [["lib", "foo"], ["lib", "bar"], ["README.md"]]
        files = FileTreeZipper.fromPaths WebData.NotAsked paths
    in
        { files = files
        , packageName = "absinthe"
        , packageVersion = "0.1.0"
        , baseUrl = flags.baseUrl
        }
