defmodule HexView.Registry do
  use GenServer

  require Logger

  @compile {:parse_transform, :ms_transform}

  def start_link(name, opts \\ []) do
    default  = Application.fetch_env!(:hex_view, __MODULE__)
    opts     = Keyword.merge(opts, default)
    storage  = Keyword.fetch!(opts, :storage)
    base_url = Keyword.fetch!(opts, :base_url)
    refresh  = Keyword.fetch!(opts, :refresh)
    GenServer.start_link(__MODULE__, {name, storage, base_url, refresh}, name: name)
  end

  def list_files(registry, name, version) do
    key = {name, version}
    case :ets.lookup(registry, key) do
      [{^key, files}] -> {:ok, files}
      []              -> :error
    end
  end

  def find_file(registry, name, version, path) do
    with {:ok, files} <- list_files(registry, name, version),
         :ok          <- check_file_exists(files, path) do
      {:ok, Path.join([storage(registry), name, version, path])}
    end
  end

  defp check_file_exists(files, path),
    do: if(path in files, do: :ok, else: :error)

  defp storage(registry),
    do: :ets.lookup_element(registry, :"$storage", 2)

  @doc false
  def init({name, storage, base_url, refresh}) do
    table = load_or_create_table(name, storage)
    send(self(), :refresh)
    timer = Process.send_after(self(), :refresh, refresh)
    {:ok, %{table: table, storage: storage, name: name,
            base_url: base_url,
            timer: timer, refresh: refresh}}
  end

  @doc false
  def handle_info(:refresh, %{timer: timer, refresh: refresh} = state) do
    Logger.info("Refreshing package registry")
    Process.cancel_timer(timer)
    refresh_data(state)
    timer = Process.send_after(self(), :refresh, refresh)
    {:noreply, %{state | timer: timer}}
  end

  def handle_info({:new_packages, packages}, %{table: table} = state) do
    package_objects =
      Enum.map(packages, fn {package, version, files} ->
        {{package, version}, files}
      end)
    true = :ets.insert(table, package_objects)
    persist_table(state)
    {:noreply, state}
  end

  def handle_info(msg, state) do
    super(msg, state)
  end

  defp persist_table(%{table: table, storage: storage, name: name}) do
    case :ets.tab2file(table, etsfile_path(name, storage)) do
      :ok ->
        :ok
      {:error, reason} = error ->
        Logger.warn("Failed to persist the registry cache: #{inspect reason}")
        error
    end
  end

  defp load_or_create_table(name, storage) do
    case :ets.file2tab(etsfile_path(name, storage)) do
      {:ok, table} ->
        table
      {:error, reason} ->
        Logger.warn("Failed to open registry cache: #{inspect reason}")
        table = :ets.new(__MODULE__, [:named_table, read_concurrency: true])
        :ets.insert(table, {:"$storage", storage})
        table
    end
  end

  defp refresh_data(%{table: table, storage: storage}) do
    ms = :ets.fun2ms(fn {{package, version}, _} -> {package, version} end)
    data = :ets.select(table, ms)
    Task.Supervisor.start_child(HexView.Registry.TaskSupervisor,
      HexView.Registry.Diff, :calculate, [self(), data, storage])
  end

  defp etsfile_path(name, storage),
    do: [storage, "#{name}-registry.ets"] |> Path.join |> String.to_charlist
end
