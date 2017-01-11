defmodule HexView.Web.ElmController do
  use HexView.Web, :controller

  def package(conn, _) do
    render(conn, HexView.Web.ElmView, "package.html")
  end
end
