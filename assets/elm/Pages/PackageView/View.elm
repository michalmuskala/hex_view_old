module Pages.PackageView.View
    exposing
        ( view
        )

import Bootstrap exposing (..)
import Data.FileTreeZipper as FileTreeZipper exposing (FileTreeZipper)
import Data.WebData as WebData exposing (WebData)
import Html exposing (Html, button, div, text, ul, li, h1, small, a)
import Html.Attributes exposing (href)
import Html.Events exposing (onClick)
import Markdown
import Pages.PackageView.Model as Model exposing (Model, Files)
import Pages.PackageView.Update as Update exposing (Msg(..))


view : Model a -> Html Msg
view model =
    let
        nav =
            navbar []

        content =
            main_ []
                [ segmentedHeading model.packageName model.packageVersion
                , renderBreadcrumbs model
                , renderTree model.files
                , renderCurrentFile (FileTreeZipper.contentWithName model.files)
                ]
    in
        div []
            [ nav
            , content
            ]


renderBreadcrumbs : Model a -> Html Msg
renderBreadcrumbs model =
    let
        crumbs =
            FileTreeZipper.breadcrumbs model.files
    in
        breadcrumbs GoUp model.packageName crumbs


renderTree : Files -> Html Msg
renderTree files =
    let
        link idx value =
            a [ href "#", onClick (GoToChild idx) ] [ text value ]

        buildRow row =
            case row of
                FileTreeZipper.Directory idx path ->
                    [ text "dir", link idx path, text "the end" ]
                FileTreeZipper.ChildFile idx path ->
                    [ text "file", link idx path, text "the end" ]

        rows =
            files
                |> FileTreeZipper.list
                |> List.map buildRow

        headers =
            [ "icon", "file", "the end" ]
    in
        fileTable headers rows


renderCurrentFile : Maybe (String, WebData String) -> Html Msg
renderCurrentFile file =
    case file of
        Nothing ->
            text "no file"
        Just (_, WebData.NotAsked) ->
            text "initializing"
        Just (_, WebData.Loading) ->
            text "loading"
        Just (_, WebData.Failure error) ->
            text "error"
        Just (name, WebData.Success file) ->
            case Debug.log "name" name of
                "README.md" ->
                    Markdown.toHtml [] file

                _ ->
                    file
                        |> String.lines
                        |> fileContent name
