module Pages.PackageView.Model exposing
    ( Model
    , Files
    , init
    )

import Data.RootedTree as RootedTree exposing (RootedTree, RootedTreeZipper)

type alias Files = RootedTreeZipper String

type alias Model a =
    { a |
      files : Files
    , name : String
    , version : String
    }


init : Model {}
init =
    let
        paths = [["lib", "foo"], ["lib", "bar"], ["README.md"]]
        files =
            RootedTree.fromPaths paths
                |> RootedTree.treeToZipper
    in
    { files = files
    , name = "Absinthe"
    , version = "0.1.0"
    }
