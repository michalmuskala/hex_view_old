import "phoenix_html";
import {PackageView} from "vendor/elm";

let node = document.querySelector("#elm-package");
if (node) {
  PackageView.embed(node);
}
