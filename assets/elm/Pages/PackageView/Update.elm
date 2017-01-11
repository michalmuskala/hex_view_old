module Pages.PackageView.Update
    exposing
        ( Msg(..)
        , update
        )

import Api
import Data.FileTreeZipper as FileTreeZipper exposing (FileTreeZipper)
import Data.WebData as WebData exposing (WebData)
import Http
import Pages.PackageView.Model as Model exposing (Model, Files)


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
                    updateFiles (FileTreeZipper.goToChild id) model

                loadFile =
                    nextModel.files
                        |> FileTreeZipper.contentWithName
                        |> Maybe.map (\_ -> Cmd.none)
                        |> Maybe.withDefault Cmd.none
            in
                nextModel ! [loadFile]
            -- let
            --     nextModel =
            --         model
            --             |> updateFiles (TreeZipper.goToChild id)

            --     path =
            --         RootedTree.breadcrumbs nextModel.files "/"
            -- in
            --     nextModel
            --         ! [ Api.getFile ( "absinthe", "0.1.0" )
            --                 (List.reverse path)
            --                 (GotFile path)
            --                 ApiError
            --           ]

        GoUp count ->
            updateFiles (FileTreeZipper.goUp count) model ! []

        GoToRoot ->
            updateFiles FileTreeZipper.goToRoot model ! []

        GotPackageFiles paths ->
            let
                files = FileTreeZipper.fromPaths WebData.NotAsked paths
            in
                { model | files = files } ! []

        ApiError err ->
            let
                _ =
                    Debug.log "apiError" err
            in
                model ! []

        GotFile path contents ->
            model ! []
            -- let
            --     _ =
            --         Debug.log "gotFile" ( path, contents )

            --     currentFilePath =
            --         path
            --             |> List.take 1
            --             |> String.join "/"

            --     currentFile =
            --         Model.Selected currentFilePath contents
            -- in
            --     { model | currentFile = currentFile } ! []


updateFiles : (Files -> Maybe Files) -> Model a -> Model a
updateFiles update model =
    case update model.files of
        Nothing ->
            model
        Just newFiles ->
            { model | files = newFiles }
