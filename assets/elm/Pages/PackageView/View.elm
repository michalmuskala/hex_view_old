module Pages.PackageView.View exposing
    ( view
    )

import Data.RootedTree as RootedTree exposing (RootedTree, RootedTreeZipper)
import Html exposing (Html, button, div, text, ul, li, h1, small, a)
import Html.Attributes exposing (href)
import Html.Events exposing (onClick)
import Pages.PackageView.Model as Model exposing (Model, Files)
import Pages.PackageView.Update as Update exposing (Msg(..))

view : Model a -> Html Msg
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
