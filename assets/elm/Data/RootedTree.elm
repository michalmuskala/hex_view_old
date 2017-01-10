module Data.RootedTree exposing
    ( RootedTree
    , RootedTreeZipper
    , fromPaths
    , treeToZipper
    , children
    , breadcrumbs
    , goUp
    , datum
    )

import Debug exposing (..)
import List.Extra as ListE
import Maybe.Extra as MaybeE
import MultiwayTree exposing (Tree(..))
import MultiwayTreeZipper exposing (Zipper)

type alias RootedTree a = Tree (Maybe a)

type alias RootedTreeZipper a = Zipper (Maybe a)

datum : RootedTreeZipper a -> Maybe a
datum =
    MultiwayTreeZipper.datum

treeToZipper : RootedTree a -> RootedTreeZipper a
treeToZipper tree =
    (tree, [])

children : RootedTreeZipper a -> List a
children (tree, _) =
    tree
        |> MultiwayTree.children
        |> List.map (MultiwayTree.datum)
        |> MaybeE.values

crumbDatum : MultiwayTreeZipper.Context a -> a
crumbDatum (MultiwayTreeZipper.Context a _ _) =
    a

breadcrumbs : RootedTreeZipper a -> a -> List a
breadcrumbs (current, crumbs) rootCrumb =
    let
        currentCrumb =
            MultiwayTree.datum current
    in
        List.map crumbDatum crumbs
            |> (::) (currentCrumb)
            |> List.map (Maybe.withDefault rootCrumb)

goUp : Int -> RootedTreeZipper a -> Maybe (RootedTreeZipper a)
goUp count zipper =
    case count of
        0 ->
            Just zipper
        n ->
            MultiwayTreeZipper.goUp zipper
                |> Maybe.andThen (goUp (count - 1))

fromPaths : List (List a) -> RootedTree a
fromPaths paths =
    List.foldl insert (Tree Nothing []) paths

fromPath : List a -> RootedTree a
fromPath path =
    case path of
        [] ->
            Tree Nothing []
        [elem] ->
            Tree (Just elem) []
        elem :: rest ->
            Tree (Just elem) [fromPath rest]

insert : List a -> RootedTree a -> RootedTree a
insert path tree =
    case (path, tree) of
        ([], _) ->
            tree
        ([head], Tree (Just datum) children) ->
            if head == datum then
                tree
            else
                Tree (Just datum) (updateChildren head [] children)
        (head :: first :: tail, Tree (Just datum) children) ->
            if head == datum then
                Tree (Just datum) (updateChildren first tail children)
            else
                Tree (Just datum) (updateChildren head (first :: tail) children)
        (head :: tail, Tree Nothing children) ->
            Tree Nothing (updateChildren head tail children)

updateChildren : a -> List a -> List (RootedTree a) -> List (RootedTree a)
updateChildren head path children =
    let
        findMatching tree =
            case tree of
                Tree Nothing _ ->
                    False
                Tree (Just elem) _ ->
                    elem == head
        child =
            fromPath (head :: path)
    in
        updateFirst findMatching (insert path) children
            |> Maybe.withDefault (child :: children)

updateFirst : (a -> Bool) -> (a -> a) -> List a -> Maybe (List a)
updateFirst finder update list =
    ListE.findIndex finder list
        |> Maybe.andThen (\x -> ListE.updateAt x update list)
