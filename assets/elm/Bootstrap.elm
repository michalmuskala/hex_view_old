module Bootstrap exposing
    ( row
    , container
    , navbar
    , main_
    , breadcrumbs
    , segmentedHeading
    , fileTable
    , fileContent
    )

import Data.FileTreeZipper exposing (ListResult(..))
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

breadcrumbs : (Int -> a) -> String -> List (Int, String) -> Html a
breadcrumbs action root elements =
    let
        click idx =
            onClick <| action <| idx

        buildElement element =
            case element of
                (0, path) ->
                    span [ class "breadcrumb-item active" ] [ text path ]
                (idx, path) ->
                    a [ class "breadcrumb-item", href "#", click idx ] [ text path ]

        addRoot elements =
            case elements of
                (idx, _) :: _ ->
                    (idx + 1, root) :: elements
                [] ->
                    []
    in
        case elements of
            (idx, _) :: _ ->
                Html.nav [ class "breadcrumb" ]
                    <| List.map buildElement ((idx + 1, root) :: elements)
            [] ->
                Html.div [] []

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
        if rows == [] then
            div [] []
        else
            table [ class "table" ] [ thead_, tbody_ ]

fileContent : String -> List String -> Html a
fileContent name lines =
    let
        buildRow idx line =
            span [ class "line" ] [ text line ]

        buildLineNumber idx =
            a [ href "#" ] [ text (toString idx) ]

        block =
            pre [] [ code [] (List.indexedMap buildRow lines) ]

        length = List.length lines

        lineNumbers =
            List.range 1 length
                |> List.map buildLineNumber

        content =
            div [ class "file-content" ]
                [ div [ class "line-numbers" ] lineNumbers
                , block
                ]

        lineCount = (toString length) ++ " lines"

        header =
            div [ class "card-header file-data" ]
                [ strong [] [ text name ]
                , text " "
                , small [ class "text-muted" ] [ text lineCount ]
                ]
    in
        div [ class "card" ] [ header, content ]
