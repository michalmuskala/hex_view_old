module Pages.PackageView.Update
    exposing
        ( Msg(..)
        , update
        )

import Api
import Data.FileTreeZipper as FileTreeZipper exposing (FileTreeZipper)
import Data.WebData as WebData exposing (WebData)
import Http
import List.Nonempty as Nonempty exposing (Nonempty)
import Pages.PackageView.Model as Model exposing (Model, Files)


type Msg
    = GoToChild Int
    | GoUp Int
    | GoToRoot
    | GotPackageFiles (List (List String))
    | ApiError Http.Error
    | GotFile (Nonempty String) (WebData String)


update : Msg -> Model a -> ( Model a, Cmd Msg )
update msg model =
    case msg of
        GoToChild id ->
            let
                nextModel =
                    updateFiles (FileTreeZipper.goToChild id) model

                ask (path, content) =
                    Api.getFile model model.package
                        (GotFile path)
                        (Nonempty.toList path)

                markLoading =
                    updateFiles (Just << FileTreeZipper.replaceContent WebData.Loading)

                unlessLoaded cmd =
                    nextModel.files
                        |> FileTreeZipper.contentWithName
                        |> Maybe.map Tuple.second
                        |> Maybe.andThen (WebData.unlessLoaded cmd)

                (loadingModel, loadFile) =
                    nextModel.files
                        |> FileTreeZipper.contentWithName
                        |> Maybe.map ask
                        |> Maybe.andThen unlessLoaded
                        |> Maybe.map ((,) (markLoading nextModel))
                        |> Maybe.withDefault (nextModel, Cmd.none)
            in
                loadingModel ! [loadFile]

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
            let
                _ =
                    Debug.log "gotFile" ( path, contents )

                isSamePath =
                    model.files
                        |> FileTreeZipper.contentWithName
                        |> Maybe.map (Tuple.first)
                        |> Maybe.map ((==) path)
                        |> Maybe.withDefault False

                updateContent =
                    if isSamePath then
                        updateFiles (Just << FileTreeZipper.replaceContent contents)
                    else
                        identity
            in
                (updateContent model) ! []


updateFiles : (Files -> Maybe Files) -> Model a -> Model a
updateFiles update model =
    case update model.files of
        Nothing ->
            model
        Just newFiles ->
            { model | files = newFiles }
