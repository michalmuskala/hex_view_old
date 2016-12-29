defmodule HexView.Web.ElmController do
  use HexView.Web, :controller

  def action(conn, _) do
    render(conn, HexView.Web.ElmView, "elm.html")
  end
end
