module Pages.PackageView.Update
    exposing
        ( Msg(..)
        , update
        )

import Data.RootedTree as RootedTree exposing (RootedTree, RootedTreeZipper)
import MultiwayTreeZipper as TreeZipper
import Pages.PackageView.Model as Model exposing (Model, Files)
import Http
import Api


type Msg
    = GoToChild Int
    | GoUp Int
    | GoToRoot
    | GotPackageFiles (List (List String))
    | ApiError Http.Error
    | GotFile (List String) String


update : Msg -> Model a -> ( Model a, Cmd Msg )
update msg model =
    case msg of
        GoToChild id ->
            let
                nextModel =
                    model
                        |> updateFiles (TreeZipper.goToChild id)

                path =
                    RootedTree.breadcrumbs nextModel.files "/"
            in
                nextModel
                    ! [ Api.getFile ( "absinthe", "0.1.0" )
                            (List.reverse path)
                            (GotFile path)
                            ApiError
                      ]

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

        GotFile path contents ->
            let
                _ =
                    Debug.log "gotFile" ( path, contents )

                currentFilePath =
                    path
                        |> List.take 1
                        |> String.join "/"

                currentFile =
                    Model.Selected currentFilePath contents
            in
                { model | currentFile = currentFile } ! []


updateFiles : (Files -> Maybe Files) -> Model a -> Model a
updateFiles update model =
    case update model.files of
        Nothing ->
            model

        Just newFiles ->
            { model | files = newFiles }
