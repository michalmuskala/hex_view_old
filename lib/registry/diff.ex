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
    packages
    |> filter_small_packages
    |> limit_downloads(download_limit())
    |> async_stream(&download_package(&1, recipient, base_path))
    |> Stream.run
  end

  defp filter_small_packages(stream) do
    size_limit = small_package_limit()
    stream
    |> async_stream(&{package_size(&1), &1})
    |> Stream.flat_map(fn
      {{:ok, size}, {name, version}} when size > size_limit ->
        Logger.warn("Rejecting package #{name}/#{version}: too big with #{size / 1024}KB")
        []
      {{:ok, _}, data} ->
        [data]
      {{:error, reason}, {name, version}} ->
        Logger.error("Failed to process package #{name}/#{version}: #{inspect reason}")
        []
    end)
  end

  defp async_stream(stream, fun) do
    Task.Supervisor.async_stream_nolink(HexView.Registry.TaskSupervisor,
      stream, fun, timeout: 10_000, max_concurrency: System.schedulers_online * 2)
    |> Stream.filter_map(&match?({:ok, _}, &1), &elem(&1, 1))
  end

  defp limit_downloads(packages, :infinity), do: packages
  defp limit_downloads(packages, limit),     do: Stream.take(packages, limit)

  defp package_size({name, version}) do
    case :hackney.head(package_url(name, version), [], "") do
      {:ok, 200, headers} ->
        headers = :hackney_headers.new(headers)
        size = :hackney_headers.get_value("content-length", headers)
        {:ok, String.to_integer(size)}
      other ->
        {:error, {:package, :size, other}}
    end
  end

  defp download_package({name, version}, recipient, base_path) do
    with {:ok, tarball} <- download_tarball(name, version),
         path = Path.join([base_path, name, version]),
         File.mkdir_p!(path),
         {:ok, files} <- extract_tarball(tarball, path) do
      Logger.info("Processed package #{name}/#{version}")
      send(recipient, {:new_packages, [{name, version, files}]})
    else
      {:error, reason} ->
        Logger.error("Failed to process package #{name}/#{version}: #{inspect reason}")
        exit({name, version, reason})
    end
  end

  defp download_tarball(package, version) do
    case :hackney.get(package_url(package, version), [], "", [:with_body]) do
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
         meta_files   = Enum.map(meta["files"], &filename/1),
         :ok          <- extract_files(files["contents.tar.gz"], meta_files, to_path) do
      {:ok, meta_files}
    else
      {:error, reason} ->
        {:error, {:package, :extraction, reason}}
    end
  end

  defp extract_files(blob, files, path) do
    files = Enum.map(files, &String.to_charlist/1)
    path  = String.to_charlist(path)
    :erl_tar.extract({:binary, blob}, [:compressed, cwd: path, files: files])
  end

  defp filename({name, _content}), do: name
  defp filename(name),             do: name

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

  defp package_url(package, version),
    do:  Path.join([base_url(), "tarballs", "#{package}-#{version}.tar"])

  defp base_url(), do: registry_config()[:base_url]

  defp download_limit(), do: registry_config()[:download_limit]

  defp small_package_limit(), do: registry_config()[:small_package_limit]

  defp registry_config(),
    do: Application.fetch_env!(:hex_view, HexView.Registry)
end
