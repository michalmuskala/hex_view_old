defmodule HexView.Registry.Diff do
  require Logger

  @compile {:parse_transform, :ms_transform}
  @package_files ["VERSION", "CHECKSUM", "metadata.config", "contents.tar.gz"]
  @registry_version 4
  @tarball_version "3"

  def calculate(recipient, data, base_path) do
    with {:ok, registry} <- download_registry(base_path),
         {:ok, packages} <- extract_packages(registry) do
      new_packages = generate_diff(packages, data)
      download_packages(new_packages, base_path, recipient)
      :ok
    else
      {:error, reason} ->
        Logger.error("Failed to refresh registry: #{inspect reason}")
    end
  end

  defp download_registry(base_path) do
    File.mkdir_p!(base_path)
    url  = Path.join([base_url(), "registry.ets.gz"])
    path = Path.join([base_path, "registry.ets.gz"])
    case :hackney.get(url, [], "", [:with_body]) do
      {:ok, 200, _headers, body} ->
        uncompressed = :zlib.gunzip(body)
        File.write!(path, uncompressed)
        {:ok, path}
      response ->
        {:error, {:registry, :download, response}}
    end
  end

  defp extract_packages(registry) do
    path = String.to_charlist(registry)
    with {:ok, tid} <- :ets.file2tab(path, verify: true),
         :ok        <- check_registry_version(tid) do
      ms = :ets.fun2ms(fn {package, [versions | _]} when is_binary(package) and is_list(versions) ->
        {package, versions}
      end)
      data = for {package, versions} <- :ets.select(tid, ms), version <- versions do
        {package, version}
      end
      {:ok, data}
    else
      {:error, reason} -> {:error, {:registry, :extraction, reason}}
    end
  end

  defp generate_diff(registry, cached) do
    registry = Enum.sort(registry)
    cached   = Enum.sort(cached)
    do_generate_diff(registry, cached)
  end

  defp do_generate_diff(registry, []),
    do: registry
  defp do_generate_diff([], cached) do
    Logger.error("Packages missing from registry: #{inspect cached}")
    []
  end
  defp do_generate_diff([new_package | registry], [package | cached])
      when new_package < package,
    do: [new_package | do_generate_diff(registry, [package | cached])]
  defp do_generate_diff([package | _] = registry, [missing_package | _] = cached)
      when package > missing_package do
    {missing, cached} = Enum.split_while(cached, &(package > &1))
    Logger.error("Packages missing from registry: #{inspect missing}")
    do_generate_diff(registry, cached)
  end
  defp do_generate_diff([package | registry], [package | cached]),
    do: do_generate_diff(registry, cached)

  defp download_packages(packages, base_path, recipient) do
    Process.flag(:trap_exit, true)
    packages
    |> Task.async_stream(fn {name, version} ->
      download_package(name, version, base_path)
    end, max_concurrency: System.schedulers_online * 2)
    |> Stream.map(&log_package_download_result/1)
    |> Stream.filter_map(&match?({:ok, _}, &1), &elem(&1, 1))
    |> Enum.each(fn data ->
      send(recipient, {:new_packages, [data]})
    end)
    Process.flag(:trap_exit, false)
  end

  defp download_package(name, version, base_path) do
    with {:ok, tarball} <- download_tarball(name, version),
         path = Path.join([base_path, name, version]),
         File.mkdir_p!(path),
         {:ok, files} <- extract_tarball(tarball, path) do
      Logger.info("Processed package #{name}/#{version}")
      {name, version, files}
    else
      {:error, reason} ->
        exit({name, version, reason})
    end
  end

  defp log_package_download_result({:ok, {name, version, _}}),
    do: Logger.info("Processed package #{name}/#{version}")
  defp log_package_download_result({:exit, {name, version, reason}}),
    do: Logger.error("Failed to process package #{name}/#{version}: #{inspect reason}")

  defp download_tarball(package, version) do
    url = Path.join([base_url(), "tarballs", "#{package}-#{version}.tar"])
    case :hackney.get(url, [], "", [:with_body]) do
      {:ok, 200, _headers, body} ->
        {:ok, body}
      response ->
        {:error, {:package, :download, package, version, response}}
    end
  end

  defp extract_tarball(tarball, to_path) do
    with {:ok, files} <- :erl_tar.extract({:binary, tarball}, [:memory]),
         files        = files_map(files),
         :ok          <- check_expected_files(files),
         :ok          <- check_tarball_version(files),
         :ok          <- check_checksum(files),
         {:ok, meta}  <- extract_metadata(files),
         :ok          <- extract_files(files["contents.tar.gz"], meta["files"], to_path) do
      {:ok, Enum.map(meta["files"], &{&1, Path.join(to_path, &1)})}
    else
      {:error, reason} ->
        {:error, {:package, :extraction, reason}}
    end
  end

  defp extract_files(blob, files, path) do
    files = Enum.map(files, fn {name, _} -> String.to_charlist(name) end)
    path  = String.to_charlist(path)
    :erl_tar.extract({:binary, blob}, [:compressed, cwd: path, files: files])
  end

  defp check_expected_files(files) do
    case @package_files -- Map.keys(files) do
      []      -> :ok
      missing -> {:error, {:missing_files, missing}}
    end
  end

  defp check_tarball_version(%{"VERSION" => @tarball_version}),
    do: :ok
  defp check_tarball_version(_),
    do: {:error, :unsupported_version}

  defp check_checksum(files) do
    case Base.decode16(files["CHECKSUM"], case: :mixed) do
      {:ok, checksum} ->
        blob = [files["VERSION"], files["metadata.config"], files["contents.tar.gz"]]
        case :crypto.hash(:sha256, blob) do
          ^checksum -> :ok
          _         -> {:error, :checksum_mismatch}
        end
      :error ->
        {:error, :checksum_invalid}
    end
  end

  defp extract_metadata(%{"metadata.config" => string}) do
    string = String.to_char_list(string)
    case :safe_erl_term.string(string) do
      {:ok, tokens, _line} ->
        try do
          terms = :safe_erl_term.terms(tokens)
          result = Enum.into(terms, %{})
          {:ok, result}
        rescue
          FunctionClauseError ->
            {:error, "invalid terms"}
          ArgumentError ->
            {:error, "not in key-value format"}
        end
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp files_map(files) do
    Enum.into(files, %{}, fn {name, contents} -> {to_string(name), contents} end)
  end

  defp check_registry_version(tid) do
    case :ets.lookup(tid, :"$$version$$") do
      [{:"$$version$$", @registry_version}] -> :ok
      _                                     -> {:error, :unsupported_version}
    end
  end

  defp base_url(),
    do: Application.fetch_env!(:hex_view, HexView.Registry)[:base_url]
end
