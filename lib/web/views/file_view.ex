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

  defp files_to_tree(conn, files) do
    files
    |> Enum.map(&String.split(&1, "/"))
    |> Enum.map(&{&1, {:path, &1}})
    |> build_raw_tree
    |> build_html_tree(conn)
    |> IO.inspect
  end

  defp build_html_tree({dir, files}, conn) when is_list(files) do
    input = tag(:input, id: dir, type: :checkbox)
    label = content_tag(:label, dir, for: dir)
    tree = build_html_tree(files, conn)
    content_tag(:li, [input, label | tree])
  end

  defp build_html_tree({file, {:path, path}}, conn) do
    %{package: package, version: version} = conn.assigns
    content_tag(:li, link(file, to: file_path(conn, :show, package, version, path)))
  end

  defp build_html_tree(list, conn) when is_list(list) do
    content = Enum.map(list, &build_html_tree(&1, conn))
    content_tag(:ul, content)
  end

  defp build_raw_tree([{[], name}]), do: name
  defp build_raw_tree(list) when is_list(list) do
    list
    |> Enum.group_by(&hd(elem(&1, 0)), &to_elem/1)
    |> Enum.map(fn {key, value} -> {key, build_raw_tree(value)} end)
    |> Enum.sort_by(&elem(&1, 1), &>=/2)
  end

  defp to_elem({[_|tail], name}), do: {tail, name}
end
