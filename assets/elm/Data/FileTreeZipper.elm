module Data.FileTreeZipper exposing
    ( FileTreeZipper
    , ListResult(..)
    , fromPaths
    , contentWithName
    , replaceContent
    , list
    , breadcrumbs
    , goUp
    , goToChild
    , goToRoot
    )

import Debug exposing (..)
import List.Extra as ListE
import Maybe.Extra as MaybeE
import MultiwayTree exposing (Tree(..))
import MultiwayTreeZipper exposing (Zipper)

type FileContent path content
    = Root
    | Path path
    | File path content

type ListResult path
    = Directory Int path
    | ChildFile Int path

type alias FileTree path content = Tree (FileContent path content)

type alias FileTreeZipper path content = Zipper (FileContent path content)

contentWithName : FileTreeZipper path content -> Maybe (path, content)
contentWithName zipper =
    case MultiwayTreeZipper.datum zipper of
        Root ->
            Nothing
        Path _ ->
            Nothing
        File path content ->
            Just (path, content)

replaceContent : c -> FileTreeZipper p c -> FileTreeZipper p c
replaceContent newContent (Tree datum children, crumbs) =
    let
        newDatum =
            case datum of
                Root ->
                    datum
                Path _ ->
                    datum
                File path content ->
                    File path newContent
    in
        (Tree newDatum children, crumbs)

list : FileTreeZipper path content -> List (ListResult path)
list (tree, _) =
    tree
        |> MultiwayTree.children
        |> List.map MultiwayTree.datum
        |> buildListResult

buildListResult : List (FileContent path content) -> List (ListResult path)
buildListResult content =
    let
        buildSingleResult idx data =
            case data of
                Root ->
                    Nothing
                Path path ->
                    Just (Directory idx path)
                File path _ ->
                    Just (ChildFile idx path)
    in
        content
            |> List.indexedMap buildSingleResult
            |> MaybeE.values

breadcrumbs : FileTreeZipper path content -> List (Int, path)
breadcrumbs (current, crumbs) =
    List.map crumbDatum crumbs
        |> (::) (MultiwayTree.datum current)
        |> buildListResult
        |> List.reverse
        |> List.map listResultToTuple

listResultToTuple : ListResult path -> (Int, path)
listResultToTuple result =
    case result of
        Directory idx path ->
            (idx, path)
        ChildFile idx path ->
            (idx, path)

crumbDatum : MultiwayTreeZipper.Context a -> a
crumbDatum (MultiwayTreeZipper.Context a _ _) =
    a

goUp : Int -> FileTreeZipper a b -> Maybe (FileTreeZipper a b)
goUp count zipper =
    case count of
        0 ->
            Just zipper
        n ->
            MultiwayTreeZipper.goUp zipper
                |> Maybe.andThen (goUp (count - 1))

goToChild : Int -> FileTreeZipper a b -> Maybe (FileTreeZipper a b)
goToChild =
    MultiwayTreeZipper.goToChild

goToRoot : FileTreeZipper a b -> Maybe (FileTreeZipper a b)
goToRoot =
    MultiwayTreeZipper.goToRoot

fromPaths : content -> List (List path) -> FileTreeZipper path content
fromPaths noContent paths =
    (List.foldl (insert noContent) (Tree Root []) paths, [])

fromPath : content -> List path -> FileTree path content
fromPath noContent path =
    case path of
        [] ->
            Tree Root []
        [elem] ->
            Tree (File elem noContent) []
        elem :: rest ->
            Tree (Path elem) [fromPath noContent rest]

insert : content -> List path -> FileTree path content -> FileTree path content
insert noContent path tree =
    let
        update = updateChildren noContent
    in
        case (path, tree) of
            ([], _) ->
                tree
            ([head], Tree (Path datum) children) ->
                if head == datum then
                    tree
                else
                    Tree (Path datum) (update head [] children)
            (head :: first :: tail, Tree (Path datum) children) ->
                if head == datum then
                    Tree (Path datum) (update first tail children)
                else
                    Tree (Path datum) (update head (first :: tail) children)
            (head :: tail, Tree (File datum content) children) ->
                Tree Root ((Tree (File datum content) []) :: update head tail children)
            (head :: tail, Tree Root children) ->
                Tree Root (update head tail children)

updateChildren : c -> a -> List a -> List (FileTree a c) -> List (FileTree a c)
updateChildren noContent head path children =
    let
        findMatching tree =
            case tree of
                Tree Root _ ->
                    False
                Tree (File elem _) _ ->
                    False
                Tree (Path elem) _ ->
                    elem == head
        defaultChild =
            fromPath noContent (head :: path)
    in
        updateFirst findMatching (insert noContent path) children
            |> Maybe.withDefault (defaultChild :: children)

updateFirst : (a -> Bool) -> (a -> a) -> List a -> Maybe (List a)
updateFirst finder update list =
    ListE.findIndex finder list
        |> Maybe.andThen (\x -> ListE.updateAt x update list)
