module Pages.PackageView.View exposing
    ( view
    )

import Bootstrap exposing (..)
import Data.RootedTree as RootedTree exposing (RootedTree, RootedTreeZipper)
import Html exposing (Html, button, div, text, ul, li, h1, small, a)
import Html.Attributes exposing (href)
import Html.Events exposing (onClick)
import Pages.PackageView.Model as Model exposing (Model, Files)
import Pages.PackageView.Update as Update exposing (Msg(..))

view : Model a -> Html Msg
view model =
    let
        nav = navbar []
        content = main_ []
                  [ segmentedHeading model.name model.version
                  , renderBreadcrumbs model
                  , renderTree model.files
                  ]
    in
        div []
            [ nav
            , content
            ]

renderBreadcrumbs : Model a -> Html Msg
renderBreadcrumbs model =
    let
        crumbs = RootedTree.breadcrumbs model.files model.name
    in
        breadcrumbs GoUp crumbs

renderTree : Files -> Html Msg
renderTree files =
    let
        link idx value =
            a [ href "#", onClick (GoToChild idx) ] [ text value ]

        buildRow idx value =
            [ text "icon", link idx value, text "the end" ]

        rows =
            files
                |> RootedTree.children
                |> List.indexedMap buildRow

        headers = ["icon", "file", "the end"]
    in
        fileTable headers rows
