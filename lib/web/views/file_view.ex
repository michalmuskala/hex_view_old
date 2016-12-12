defmodule HexView.Web.FileView do
  use HexView.Web, :view

  def render("index.text", %{files: files}) do
    Enum.intersperse(files, ?\n)
  end

  defp files_to_tree(files) do
    files
    |> Enum.map(&String.split(&1, "/"))
    |> build_raw_tree
    |> build_html_tree
  end

  defp build_html_tree({file, :regular}) do
    content_tag(:li, file)
  end

  defp build_html_tree({dir, files}) do
    content_tag(:li, [dir | build_html_tree(files)])
  end

  defp build_html_tree(list) when is_list(list) do
    content = Enum.map(list, &build_html_tree/1)
    content_tag(:ul, content)
  end

  defp build_raw_tree([[]]), do: :regular
  defp build_raw_tree(list) do
    list
    |> Enum.group_by(&hd/1, &tl/1)
    |> Enum.map(fn {key, value} -> {key, build_raw_tree(value)} end)
  end
end
