module Zipper exposing
    ( Zipper (..)
    , fromList
    , fromElem
    , current
    , prev
    , next
    )

type Zipper a = Zipper (List a) (List a)

fromElem : a -> Zipper a
fromElem elem =
    Zipper [] [elem]

fromList : List a -> Zipper a
fromList list =
    Zipper [] list

current : Zipper a -> Maybe a
current (Zipper _ after) =
    List.head after

prev : Zipper a -> Maybe (Zipper a)
prev (Zipper before after) =
    case before of
        [] ->
            Nothing
        elem :: before_ ->
            Just (Zipper before_ (elem :: after))

next : Zipper a -> Maybe (Zipper a)
next (Zipper before after) =
    case after of
        [] ->
            Nothing
        elem :: after_ ->
            Just (Zipper (elem :: before) after_)
