module Bootstrap exposing
    ( row
    , container
    , navbar
    , main_
    , breadcrumbs
    , segmentedHeading
    , fileTable
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

type alias Tag a = List (Attribute a) -> List (Html a) -> Html a

row : Tag a
row attrs =
    Html.div ([ class "row" ] ++ attrs)

container : Tag a
container attrs =
    Html.div ([ class "container" ] ++ attrs)

main_ : Tag a
main_ attrs =
    Html.main_ ([ class "container" ] ++ attrs)

navbar : List (Html a) -> Html a
navbar links =
    let
        linkElements = []
        body = container []
               [ Html.a [ class "navbar-brand", href "#" ] [ text "HexView" ]
               , Html.ul [ class "navbar-nav mr-auto" ] linkElements
               ]
    in
    Html.nav [ class "navbar fixed-top" ] [ body ]

breadcrumbs : (Int -> a) -> List String -> Html a
breadcrumbs action elements =
    let
        click idx =
            onClick <| action <| idx + 1

        buildElement idx name =
            a [ class "breadcrumb-item", href "#", click idx ] [ text name ]

        buildLast name =
            span [ class "breadcrumb-item active" ] [ text name ]

        renderedElements =
            case elements of
                last :: rest ->
                    rest
                        |> List.indexedMap buildElement
                        |> (::) (buildLast last)
                        |> List.reverse
                [] ->
                    []
    in
        Html.nav [ class "breadcrumb" ] renderedElements

segmentedHeading : String -> String -> Html a
segmentedHeading title subtitle =
    h2 []
        [ text title, text " "
        , small [ class "text-muted" ] [ text subtitle ]
        ]

fileTable : (List String) -> List (List (Html a)) -> Html a
fileTable headers rows =
    let
        headElements =
            List.map (\x -> th [] [ text x ]) headers

        thead_ =
            thead [ class "thead-default" ] headElements

        buildRowHead value =
            th [ scope "row" ] [ value ]

        buildRowElement value =
            td [] [ value ]

        buildRow elems =
            case elems of
                head :: rest ->
                    tr [] ((buildRowHead head) :: (List.map buildRowElement rest))
                [] ->
                    tr [] []

        tbody_ =
            tbody [] (List.map buildRow rows)
    in
        table [ class "table" ] [ thead_, tbody_ ]
