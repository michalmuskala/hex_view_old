module Data.RootedTree exposing
    ( RootedTree
    , RootedTreeZipper
    , fromPaths
    , treeToZipper
    , zipperToTree
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

type Rooted a = Root | Leaf a

type alias RootedTree a = Tree (Rooted a)

type alias RootedTreeZipper a = Zipper (Rooted a)

datum : RootedTreeZipper a -> Maybe a
datum =
    MultiwayTreeZipper.datum >> rootedToMaybe

treeToZipper : RootedTree a -> RootedTreeZipper a
treeToZipper tree =
    (tree, [])

zipperToTree : RootedTreeZipper a -> RootedTree a
zipperToTree (tree, _) =
    tree

children : RootedTree a -> List a
children (Tree _ children) =
    List.map (MultiwayTree.datum >> rootedToMaybe) children
        |> MaybeE.values

rootedToMaybe : Rooted a -> Maybe a
rootedToMaybe rooted =
    case rooted of
        Root ->
            Nothing
        Leaf a ->
            Just a

crumbDatum : MultiwayTreeZipper.Context a -> a
crumbDatum (MultiwayTreeZipper.Context a _ _) =
    a

breadcrumbs : RootedTreeZipper a -> a -> List a
breadcrumbs (current, crumbs) rootCrumb =
    let
        currentCrumb =
            MultiwayTree.datum current
                |> rootedToMaybe
    in
        List.map (crumbDatum >> rootedToMaybe) crumbs
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
    List.foldl insert (Tree Root []) paths

fromPath : List a -> RootedTree a
fromPath path =
    case path of
        [] ->
            Tree Root []
        [elem] ->
            Tree (Leaf elem) []
        elem :: rest ->
            Tree (Leaf elem) [fromPath rest]

insert : List a -> RootedTree a -> RootedTree a
insert path tree =
    case (path, tree) of
        ([], _) ->
            tree
        ([head], Tree (Leaf datum) children) ->
            if head == datum then
                tree
            else
                Tree (Leaf datum) (updateChildren head [] children)
        (head :: first :: tail, Tree (Leaf datum) children) ->
            if head == datum then
                Tree (Leaf datum) (updateChildren first tail children)
            else
                Tree (Leaf datum) (updateChildren head (first :: tail) children)
        (head :: tail, Tree Root children) ->
            Tree Root (updateChildren head tail children)

updateChildren : a -> List a -> List (RootedTree a) -> List (RootedTree a)
updateChildren head path children =
    let
        findMatching tree =
            case tree of
                Tree Root _ ->
                    False
                Tree (Leaf elem) _ ->
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
