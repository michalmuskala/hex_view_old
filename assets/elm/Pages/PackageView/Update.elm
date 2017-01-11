module Pages.PackageView.Update
    exposing
        ( Msg(..)
        , update
        )

import Data.RootedTree as RootedTree exposing (RootedTree, RootedTreeZipper)
import MultiwayTreeZipper as TreeZipper
import Pages.PackageView.Model as Model exposing (Model, Files)
import Http


type Msg
    = GoToChild Int
    | GoUp Int
    | GoToRoot
    | GotPackageFiles (List (List String))
    | ApiError Http.Error


update : Msg -> Model a -> ( Model a, Cmd Msg )
update msg model =
    case msg of
        GoToChild id ->
            updateFiles (TreeZipper.goToChild id) model ! []

        GoUp count ->
            updateFiles (RootedTree.goUp count) model ! []

        GoToRoot ->
            updateFiles TreeZipper.goToRoot model ! []

        GotPackageFiles paths ->
            let
                _ =
                    Debug.log "gotPackageFiles" paths

                files =
                    paths
                        |> RootedTree.fromPaths
                        |> RootedTree.treeToZipper
            in
                { model | files = files } ! []

        ApiError err ->
            let
                _ =
                    Debug.log "apiError" err
            in
                model ! []


updateFiles : (Files -> Maybe Files) -> Model a -> Model a
updateFiles update model =
    case update model.files of
        Nothing ->
            model

        Just newFiles ->
            { model | files = newFiles }
