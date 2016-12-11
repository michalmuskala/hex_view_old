defmodule HexView.Registry do
  use GenServer

  require Logger

  @compile {:parse_transform, :ms_transform}

  def start_link(opts \\ []) do
    default  = Application.fetch_env!(:hex_view, __MODULE__)
    opts     = Keyword.merge(opts, default)
    storage  = Keyword.fetch!(opts, :storage)
    base_url = Keyword.fetch!(opts, :base_url)
    refresh  = Keyword.fetch!(opts, :refresh)
    GenServer.start_link(__MODULE__, {storage, base_url, refresh}, opts)
  end

  def init({storage, base_url, refresh}) do
    table = load_or_create_table(storage)
    send(self(), :refresh)
    timer = Process.send_after(self(), :refresh, refresh)
    {:ok, %{table: table, storage: storage,
            base_url: base_url,
            timer: timer, refresh: refresh}}
  end

  def handle_info(:refresh, %{timer: timer, refresh: refresh} = state) do
    Process.cancel_timer(timer)
    refresh_data(state)
    timer = Process.send_after(self(), :refresh, refresh)
    persist_table(state)
    {:noreply, %{state | timer: timer}}
  end

  def handle_info({:new_packages, packages}, %{table: table} = state) do
    package_objects =
      Enum.map(packages, fn {package, version, files} ->
        {{package, version}, Enum.map(files, &elem(&1, 0))}
      end)
    file_objects =
      Enum.flat_map(packages, fn {package, version, files} ->
        Enum.map(files, fn {name, path} -> {{package, version, name}, path} end)
      end)
    true = :ets.insert(table, package_objects ++ file_objects)
    {:noreply, state}
  end

  defp persist_table(%{table: table, storage: storage}) do
    case :ets.tab2file(table, etsfile_path(storage)) do
      :ok ->
        :ok
      {:error, reason} = error ->
        Logger.warn("Failed to persist the registry cache: #{inspect reason}")
        error
    end
  end

  defp load_or_create_table(storage) do
    case :ets.file2tab(etsfile_path(storage)) do
      {:ok, table} ->
        table
      {:error, reason} ->
        Logger.warn("Failed to open registry cache: #{inspect reason}")
        :ets.new(__MODULE__, [read_concurrency: true])
    end
  end

  defp refresh_data(%{table: table, storage: storage}) do
    ms = :ets.fun2ms(fn {{package, version}, _} -> {package, version} end)
    data = :ets.select(table, ms)
    Task.start_link(HexView.Registry.Diff, :calculate, [self(), data, storage])
  end

  defp etsfile_path(storage),
    do: [storage, "registry.ets"] |> Path.join |> String.to_charlist
end
