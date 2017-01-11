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
            model ! [ Api.getPackage
                          (model.packageName, model.packageVersion)
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



-- :  { init : (model, Cmd msg), update : msg -> model -> (model, Cmd msg), subscriptions : model -> Sub msg, view : model -> Html msg }
