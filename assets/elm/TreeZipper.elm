module TreeZipper exposing
    ( fromTree
    , current
    , prev
    , next
    , parent
    , firstChild
    )

import Tree exposing (..)
import Zipper exposing (..)

type TreeZipper a = TreeZipper (List (Zipper (Tree a))) (Zipper (Tree a))

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
        |> Maybe.andThen Tree.forest
        |> Maybe.map (Zipper.fromList >> (TreeZipper (forest :: before)))

parent : TreeZipper a -> Maybe (TreeZipper a)
parent (TreeZipper before forest) =
    case before of
        [] ->
            Nothing
        parent :: before_ ->
            Just (TreeZipper before_ parent)
