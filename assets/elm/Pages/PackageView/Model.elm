module Pages.PackageView.Model exposing
    ( Model
    , Flags
    , Files
    , init
    )

import Data.FileTreeZipper as FileTreeZipper exposing (FileTreeZipper)
import Data.Package as Package exposing (Package)
import Data.WebData as WebData exposing (WebData)

type alias Path = String

type alias FileContent = String

type alias Files = FileTreeZipper Path (WebData FileContent)

type alias Flags =
    { baseUrl : String
    , packageName : String
    , packageVersion : String
    }

type alias Model a =
    { a |
      files : Files
    , baseUrl : String
    , package : Package
    }


init : Flags -> Model {}
init flags =
    let
        files = FileTreeZipper.fromPaths WebData.NotAsked []

        package = Package.package flags.packageName flags.packageVersion
    in
        { files = files
        , package = package
        , baseUrl = flags.baseUrl
        }
