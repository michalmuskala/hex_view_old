defmodule HexView.Web.FileController do
  use HexView.Web, :controller

  alias HexView.Registry

  def index(conn, %{"package" => package, "version" => version}) do
    case Registry.list_files(Registry, package, version) do
      {:ok, files} ->
        render(conn, :index, files: files, package: package, version: version)
      :error ->
        conn
        |> put_status(:not_found)
        |> render(HexView.ErrorView, :"404")
    end
  end

  def show(conn, %{"package" => package, "version" => version, "path" => path}) do
    path = Path.join(path)
    case Registry.find_file(Registry, package, version, path) do
      {:ok, file} ->
        {:ok, files} = Registry.list_files(Registry, package, version)
        render_file(conn, get_format(conn), package: package, version: version, file: file, files: files, path: path)
      :error ->
        conn
        |> put_status(:not_found)
        |> render(HexView.ErrorView, :"404")
    end
  end

  defp render_file(conn, "text", assigns),
    do: send_file(conn, :ok, assigns[:file])
  defp render_file(conn, _any  , assigns),
    do: render(conn, :show, update_in(assigns[:file], &File.read!/1))
end
