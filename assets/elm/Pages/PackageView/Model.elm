module Pages.PackageView.Model exposing
    ( Model
    , Files
    , init
    )

import Data.FileTreeZipper as FileTreeZipper exposing (FileTreeZipper)
import Data.WebData as WebData exposing (WebData)

type alias Files = FileTreeZipper String (WebData String)

type alias Model a =
    { a |
      files : Files
    , packageName : String
    , packageVersion : String
    }


init : Model {}
init =
    let
        paths = [["lib", "foo"], ["lib", "bar"], ["README.md"]]
        files = FileTreeZipper.fromPaths WebData.NotAsked paths
    in
        { files = files
        , packageName = "absinthe"
        , packageVersion = "0.1.0"
        }
