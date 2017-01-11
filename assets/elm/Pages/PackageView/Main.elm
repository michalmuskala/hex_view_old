module Pages.PackageView exposing (main)

import Html exposing (Html)
import Pages.PackageView.Model as Model exposing (Model)
import Pages.PackageView.Update as Update exposing (Msg(..))
import Pages.PackageView.View as View
import Api exposing (getPackage)


main : Program Never (Model {}) Msg
main =
    Html.program
        { init =
            ( Model.init
            , Api.getPackage ( "absinthe", "0.1.0" ) GotPackageFiles ApiError
            )
        , update = Update.update
        , subscriptions = subscriptions
        , view = View.view
        }


subscriptions : Model a -> Sub Msg
subscriptions model =
    Sub.none



-- :  { init : (model, Cmd msg), update : msg -> model -> (model, Cmd msg), subscriptions : model -> Sub msg, view : model -> Html msg }
