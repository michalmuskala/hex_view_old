import "phoenix_html";
import {Pages} from "vendor/elm";

let node = document.querySelector("#elm-package");
if (node) {
  Pages.PackageView.embed(node);
}
