module Tree exposing
    ( Tree (..)
    , fromPaths
    , elem
    , forest
    )

type Tree a
    = Root (Forest a)
    | Node a (Forest a)

type alias Forest a = List (Tree a)

elem : Tree a -> Maybe a
elem tree =
    case tree of
        Root _ ->
            Nothing
        Node elem _ ->
            Just elem

forest : Tree a -> Forest a
forest tree =
    case tree of
        Root forest ->
            forest
        Node _ forest ->
            forest

fromPaths : List (List a) -> Tree a
fromPaths paths =
    List.foldl insert (Root []) paths

fromPath : List a -> Tree a
fromPath path =
    case path of
        [] ->
            Root []
        [elem] ->
            Node elem []
        elem :: rest ->
            Node elem [fromPath rest]

insert : List a -> Tree a -> Tree a
insert path tree =
    case (path, tree) of
        ([], tree) ->
            tree
        (head :: tail as path, (Node elem forest) as node) ->
            if head == elem then
                Node elem (insertToForest path forest)
            else
                -- this should be never reached going through fromPaths
                Root [fromPath path, node]
        (path, Root forest) ->
            Root (insertToForest path forest)

insertToForest : List a -> Forest a -> Forest a
insertToForest path forest =
    case (path, forest) of
        ([], forest) ->
            forest
        (path, []) ->
            [fromPath path]
        (head :: tail, (Node elem nextForest) :: forestRest) ->
            if head == elem then
                (Node elem (insertToForest tail nextForest)) :: forestRest
            else
                (Node elem nextForest) :: (insertToForest path forestRest)
        (path, (Root nextForest) :: forestRest) ->
            -- this should be never reached going through fromPaths
            (Root nextForest) :: (insertToForest path forestRest)
