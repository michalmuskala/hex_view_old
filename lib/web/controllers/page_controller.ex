defmodule HexView.Web.PageController do
  use HexView.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
