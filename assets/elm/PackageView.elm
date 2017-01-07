module PackageView exposing (main)

import Html exposing (Html, button, div, text, ul, li)
import Html.Events exposing (onClick)
import TreeZipper exposing (TreeZipper)

-- main : Html Msg
main =
    Html.beginnerProgram { model = model, view = view, update = update }


-- MODEL

type alias Model =
    { files : TreeZipper String }

model : Model
model =
    { files = TreeZipper.fromPaths [["lib", "foo"], ["lib", "bar"], ["README.md"]] }

-- UPDATE

type Msg = None

update : Msg -> Model -> Model
update _ model = model

-- VIEW

view : Model -> Html Msg
view model =
    div []
        [ button [ onClick None ] [ text "nothing" ]
        , renderTree model.files
        ]

renderTree : TreeZipper String -> Html Msg
renderTree tree =
    let
        lis =
            TreeZipper.forest tree
                |> List.map (\x -> li [] [ text x ])
    in
        ul [] lis
