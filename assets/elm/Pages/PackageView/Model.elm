module Pages.PackageView.Model exposing
    ( Model
    , Files
    , CurrentFile(..)
    , init
    )

import Data.RootedTree as RootedTree exposing (RootedTree, RootedTreeZipper)

type alias Files = RootedTreeZipper String

type CurrentFile
    = NotSelected
    | Loading
    | Selected String String

type alias Model a =
    { a |
      files : Files
    , name : String
    , version : String
    , currentFile : CurrentFile
    }


init : Model {}
init =
    let
        paths = [["lib", "foo"], ["lib", "bar"], ["README.md"]]
        files =
            RootedTree.fromPaths paths
                |> RootedTree.treeToZipper
        file =
            """
Litwo! Ojczyzno moja! Ty jesteś jak zdrowie. Nazywał się w pół rozmowy
odstrychnęli od Moskwy szeregów które już ochłoną i kołkiem zaszczepki
przetknięto. Podróżny zląkł się, toczył zdumione.

Był dawniej było głucho w końcu śród biesiadników siedział gość Moskal.
był w tabakierkę złotą Podkomorzy i utrzymywał, że oko pańskie konia
tuczy. Wojski na oknach donice z nami.

Panno Święta, co gród zamkowy nowogródzki ochraniasz z wolna w całym
domu i rozmyślał: Ogiński z opieki nie powiedziała kogo owa.

Usnęli wszyscy. Sędzia Podkomorzego zdał się zadziwił lecz podmurowany.
Świeciły się ziemi. Podróżny zląkł się, wieczerzę dowodzi,
że przeniosłem stoły.

Bez Suworowa to mówiąc, że on rodaków zbiera na pacierz po łacinie.
Mężczyznom dano wódkę. jak od stołu. pierwszy człowiek, co dzień
postrzegam, jak bazyliszek. asesor mniej zgorszenia.
"""
    in
    { files = files
    , name = "Absinthe"
    , version = "0.1.0"
    , currentFile = Selected "foo.exs" file
    }
