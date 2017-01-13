module Pages.PackageView exposing (main)

import Api exposing (getPackage)
import Html exposing (Html)
import Pages.PackageView.Model as Model exposing (Model, Flags)
import Pages.PackageView.Update as Update exposing (Msg(..))
import Pages.PackageView.View as View

type alias Flags =
    { baseUrl : String
    , packageName : String
    , packageVersion : String
    }

main : Program Flags (Model {}) Msg
main =
    let
        initialRequest model =
            model ! [ Api.getPackage model
                          model.package
                          GotPackageFiles
                          ApiError
                    ]

        init = Model.init >> initialRequest
    in
        Html.programWithFlags
            { init = init
            , update = Update.update
            , subscriptions = subscriptions
            , view = View.view
            }


subscriptions : Model a -> Sub Msg
subscriptions model =
    Sub.none
