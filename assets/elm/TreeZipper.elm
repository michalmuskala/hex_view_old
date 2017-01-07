module TreeZipper exposing
    ( TreeZipper
    , fromTree
    , fromPaths
    , isLeaf
    , forest
    , current
    , prev
    , next
    , parent
    , firstChild
    )

import Maybe.Extra
import Tree exposing (Tree)
import Zipper exposing (Zipper)

type TreeZipper a = TreeZipper (List (Zipper (Tree a))) (Zipper (Tree a))

fromPaths : List (List a) -> TreeZipper a
fromPaths =
    Tree.fromPaths >> fromTree

isLeaf : TreeZipper a -> Bool
isLeaf (TreeZipper _ forest) =
    Zipper.current forest
        |> Maybe.map Tree.isLeaf
        |> Maybe.withDefault False

forest : TreeZipper a -> (List a)
forest (TreeZipper _ forest) =
    let
        mapped =
            Zipper.current forest
               |> Maybe.map Tree.forest
        traverse = Maybe.Extra.traverse Tree.elem
    in
        mapped
        |> Maybe.andThen traverse
        |> Maybe.withDefault []

fromTree : Tree a -> TreeZipper a
fromTree tree =
    TreeZipper [] (Zipper.fromElem tree)

current : TreeZipper a -> Maybe a
current (TreeZipper _ forest) =
    Zipper.current forest
        |> Maybe.andThen Tree.elem

prev : TreeZipper a -> Maybe (TreeZipper a)
prev (TreeZipper before forest) =
    Zipper.prev forest
        |> Maybe.map (TreeZipper before)

next : TreeZipper a -> Maybe (TreeZipper a)
next (TreeZipper before forest) =
    Zipper.next forest
        |> Maybe.map (TreeZipper before)

firstChild : TreeZipper a -> Maybe (TreeZipper a)
firstChild (TreeZipper before forest) =
    Zipper.current forest
        |> Maybe.map Tree.forest
        |> Maybe.map (Zipper.fromList >> (TreeZipper (forest :: before)))

parent : TreeZipper a -> Maybe (TreeZipper a)
parent (TreeZipper before forest) =
    case before of
        [] ->
            Nothing
        parent :: before_ ->
            Just (TreeZipper before_ parent)
