module PackageView exposing (main)

import Data.RootedTree as RootedTree exposing (RootedTree, RootedTreeZipper)
import Debug exposing (..)
import Html exposing (Html, button, div, text, ul, li, h1, small, a)
import Html.Attributes exposing (href)
import Html.Events exposing (onClick)
import Maybe.Extra as MaybeE
import MultiwayTreeZipper

-- main : Html Msg
main =
    Html.beginnerProgram { model = model, view = view, update = update }


-- MODEL

type alias Files = RootedTreeZipper String

type alias Model =
    { files : Files
    , name : String
    , version : String
    }

model : Model
model =
    let
        paths = [["lib", "foo"], ["lib", "bar"], ["README.md"]]
        files =
            RootedTree.fromPaths paths
                |> RootedTree.treeToZipper
    in
    { files = log "files" files
    , name = "Absinthe"
    , version = "0.1.0"
    }

-- UPDATE

type Msg
    = GoToChild Int
    | GoUp Int
    | GoToRoot

update : Msg -> Model -> Model
update msg model =
    case msg of
        GoToChild id ->
            updateFiles (MultiwayTreeZipper.goToChild id) model
        GoUp count ->
            updateFiles (RootedTree.goUp count) model
        GoToRoot ->
            updateFiles MultiwayTreeZipper.goToRoot model

updateFiles : (Files -> Maybe Files) -> Model -> Model
updateFiles update model =
    case update model.files of
        Nothing ->
            model
        Just newFiles ->
            { model | files = newFiles }

-- VIEW

view : Model -> Html Msg
view model =
    div []
        [ button [ onClick GoToRoot ] [ text "nothing" ]
        , h1 [] [ text model.name, small [] [ text model.version ] ]
        , renderBreadcrumbs model.files
        , renderTree model.files
        ]

renderBreadcrumbs : Files -> Html Msg
renderBreadcrumbs files =
    let
        elem idx value =
            li [] [ a [ href "#", onClick (GoUp idx) ] [ text value ] ]
        -- final =
        --     RootedTree.datum files
        --         |> Maybe.map (\x -> li [] [ text x ])
        --         |> MaybeE.maybeToList
        -- first =
        --     li [] [ a [ href "#", onClick GoToRoot ] [ text "/" ] ]
        lis =
            RootedTree.breadcrumbs files "root"
                |> List.indexedMap elem
                |> List.reverse
    in
        ul [] lis


renderTree : Files -> Html Msg
renderTree files =
    let
        elem idx value =
            li [] [ a [ href "#", onClick (GoToChild idx) ] [ text value ] ]
        lis =
            RootedTree.zipperToTree files
                |> RootedTree.children
                |> List.indexedMap elem
    in
        ul [] lis
