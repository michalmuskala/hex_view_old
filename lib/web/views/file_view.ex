defmodule HexView.Web.FileView do
  use HexView.Web, :view

  def render("index.text", %{files: files}) do
    Enum.intersperse(files, ?\n)
  end

  defp line_numbers(file) do
    lines = file |> String.split("\n") |> Enum.count
    Enum.map(1..(lines - 1), fn idx ->
      idx = Integer.to_string(idx)
      [link(idx, to: "##{idx}", id: idx) | tag(:br)]
    end)
  end

end
