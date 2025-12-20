defmodule BlendendPlaygroundPhx.Palette.Scheme do
  @enforce_keys [:name, :colors]
  defstruct [:name, :colors, :stroke, :background, :source]
end

defmodule BlendendPlaygroundPhx.Palette do
  @moduledoc """
  Palette helper with ETS-backed storage.

  Palettes are loaded from `priv/palettes/*.json` at startup.
  Each palette carries a `source` tag so the frontend can filter by source then scheme.
  Palette names and sources are strings; prefer calls like
  `Palette.palette_by_name("VanGogh", "takawo")` or `Palette.palette_by_name("takawo.VanGogh")`.
  """

  alias BlendendPlaygroundPhx.Palette.Scheme
  @table :palette_cache

  @doc """
  Initialize ETS palette cache. Safe to call multiple times.
  """
  def init_cache do
    table = :ets.whereis(@table)

    if table == :undefined do
      :ets.new(@table, [:set, :public, :named_table, read_concurrency: true])
    end

    :ets.delete_all_objects(@table)

    load_palettes()
    |> Enum.each(fn %Scheme{name: name, source: source} = scheme ->
      key = {source || "unknown", name}
      :ets.insert(@table, {key, scheme})
    end)

    :ok
  end

  @doc """
  Fetch a palette by name.

  Accepts `"source.name"`, `{name, source}`, or `"random"`. Names and sources
  should be strings; atoms are still accepted for compatibility.
  """
  @spec palette_by_name(String.t() | atom(), String.t() | atom() | nil) :: Scheme.t()
  def palette_by_name(name, source \\ nil)

  def palette_by_name(name, source) when name in [:random, "random"] and is_list(source),
    do: fetch_random_palette(source)

  def palette_by_name(name, source) when name in [:random, "random"] do
    source
    |> pick_source_for_random()
    |> fetch_random_palette()
  end

  def palette_by_name(name, source) when is_atom(name) do
    palette_by_name(Atom.to_string(name), source)
  end

  def palette_by_name(<<_::binary>> = name, source) do
    {src, palette_name} = split_source_and_name(name, source)
    src = normalize_source(src)
    palette_name = normalize_name(palette_name)

    case lookup_scheme(palette_name, src) do
      {:ok, scheme} ->
        scheme

      {:error, {:ambiguous, sources}} ->
        raise ArgumentError,
              "palette #{palette_name} is available in multiple sources: #{Enum.join(sources, ", ")}; please specify a source"

      {:error, :not_found} ->
        raise ArgumentError, "palette not found: #{inspect({src || :any, palette_name})}"
    end
  end

  @doc """
  List palette structs for a given source.
  """
  @spec palettes_by_source(String.t() | atom()) :: [Scheme.t()]
  def palettes_by_source(source) do
    source = normalize_source(source)

    if source do
      ensure_cache()

      :ets.match_object(@table, {{source, :_}, :_})
      |> Enum.map(fn {_, scheme} -> scheme end)
      |> Enum.sort_by(& &1.name)
    else
      []
    end
  end

  @doc """
  Index of available palette names grouped by source.
  """
  @spec palettes_by_source() :: %{String.t() => [String.t()]}
  def palettes_by_source do
    ensure_cache()

    :ets.tab2list(@table)
    |> Enum.reduce(%{}, fn {{src, name}, _scheme}, acc ->
      Map.update(acc, src, [name], &[name | &1])
    end)
    |> Enum.into(%{}, fn {src, names} -> {src, names |> Enum.uniq() |> Enum.sort()} end)
  end

  @doc """
  Lists available sources (strings).
  """
  @spec palette_sources() :: [String.t()]
  def palette_sources do
    palettes_by_source()
    |> Map.keys()
    |> Enum.sort()
  end

  @doc """
  Pick a palette out of a collection or via ETS lookup.
  """
  @spec fetch_palette([Scheme.t()] | String.t() | atom(), atom() | String.t()) :: Scheme.t()
  def fetch_palette(palette_collection, name) when is_list(palette_collection) do
    palette_name = normalize_name(name)

    case Enum.find(palette_collection, fn %Scheme{name: n} -> n == palette_name end) do
      nil -> raise ArgumentError, "palette not found in collection: #{inspect(palette_name)}"
      scheme -> scheme
    end
  end

  def fetch_palette(source, name) when is_binary(source) or is_atom(source) do
    palette_by_name(name, source)
  end

  @doc """
  Choose a random palette from a source or collection.
  """
  @spec fetch_random_palette() :: Scheme.t()
  def fetch_random_palette do
    ensure_cache()

    case :ets.tab2list(@table) do
      [] -> raise ArgumentError, "no palettes available"
      list -> list |> Enum.random() |> elem(1)
    end
  end

  @spec fetch_random_palette([Scheme.t()] | String.t() | atom()) :: Scheme.t()
  def fetch_random_palette(palette_collection) when is_list(palette_collection) do
    if Enum.empty?(palette_collection) do
      raise ArgumentError, "no palettes available"
    else
      Enum.random(palette_collection)
    end
  end

  def fetch_random_palette(source) when is_binary(source) or is_atom(source) do
    source
    |> normalize_source()
    |> case do
      nil ->
        fetch_random_palette()

      src ->
        src
        |> palettes_by_source()
        |> case do
          [] -> fetch_random_palette()
          list -> fetch_random_palette(list)
        end
    end
  end

  @doc """
  Returns a random palette source.
  """
  @spec fetch_random_source() :: String.t()
  def fetch_random_source do
    case palette_sources() do
      [] -> raise ArgumentError, "no palette sources available"
      sources -> Enum.random(sources)
    end
  end

  # --- legacy wrappers / conversions ---
  @doc """
  Converts a list of hex strings into RGB triples `{r, g, b}`.
  """
  @spec from_hex_list_rgb([String.t()]) :: [
          {non_neg_integer(), non_neg_integer(), non_neg_integer()}
        ]
  def from_hex_list_rgb(hex_list) when is_list(hex_list) do
    Enum.map(hex_list, &hex_to_rgb/1)
  end

  @doc """
  Converts a list of hex strings into HSV triples `{h, s, v}`.
  """
  @spec from_hex_list_hsv([String.t()]) :: [{number(), number(), number()}]
  def from_hex_list_hsv(hex_list) when is_list(hex_list) do
    Enum.map(hex_list, &hex_to_hsv/1)
  end

  def hex_to_hsv("#" <> <<r::binary-size(2), g::binary-size(2), b::binary-size(2)>>) do
    r = String.to_integer(r, 16) / 255.0
    g = String.to_integer(g, 16) / 255.0
    b = String.to_integer(b, 16) / 255.0

    maxc = max(r, max(g, b))
    minc = min(r, min(g, b))
    delta = maxc - minc

    h =
      cond do
        delta == 0.0 -> 0.0
        maxc == r -> 60.0 * :math.fmod((g - b) / delta, 6.0)
        maxc == g -> 60.0 * ((b - r) / delta + 2.0)
        true -> 60.0 * ((r - g) / delta + 4.0)
      end
      |> normalize_hue()

    s = if maxc == 0.0, do: 0.0, else: delta / maxc
    v = maxc

    {h, s, v}
  end

  def hex_to_rgb("#" <> <<r::binary-size(2), g::binary-size(2), b::binary-size(2)>>) do
    {String.to_integer(r, 16), String.to_integer(g, 16), String.to_integer(b, 16)}
  end

  # --- internals ---

  defp lookup_scheme(name, source) do
    ensure_cache()

    cond do
      is_binary(source) ->
        case :ets.lookup(@table, {source, name}) do
          [{_, scheme}] ->
            {:ok, scheme}

          _ ->
            lookup_scheme(name, nil)
        end

      true ->
        matches = :ets.match_object(@table, {{:_, name}, :_})

        case matches do
          [] ->
            {:error, :not_found}

          [{{_, _}, scheme}] ->
            {:ok, scheme}

          list ->
            sources =
              list
              |> Enum.map(fn {{src, _}, _} -> src end)
              |> Enum.uniq()
              |> Enum.sort()

            {:error, {:ambiguous, sources}}
        end
    end
  end

  defp split_source_and_name(name, source) do
    normalized_source = normalize_source(source)
    parts = String.split(name, ".", parts: 2)

    case {normalized_source, parts} do
      {nil, [src, rest]} -> {src, rest}
      {src, [candidate, rest]} when candidate == src -> {src, rest}
      {_parts, src} when is_binary(src) -> {src, name}
      _ -> {nil, name}
    end
  end

  defp pick_source_for_random(source) when is_binary(source) or is_list(source), do: source
  defp pick_source_for_random(source) when is_atom(source), do: Atom.to_string(source)
  defp pick_source_for_random(_), do: fetch_random_source()

  defp normalize_name(name) when is_atom(name), do: Atom.to_string(name)
  defp normalize_name(<<_::binary>> = name), do: name

  defp normalize_source(source) when source in [nil, ""], do: nil
  defp normalize_source(source) when is_atom(source), do: Atom.to_string(source)
  defp normalize_source(source) when is_binary(source), do: source
  defp normalize_source(_), do: nil

  defp normalize_hue(h) when h < 0.0, do: h + 360.0
  defp normalize_hue(h), do: h

  defp ensure_cache do
    case :ets.whereis(@table) do
      :undefined -> init_cache()
      _ -> :ok
    end
  end

  defp load_palettes do
    priv_palette_files()
    |> Enum.flat_map(&load_file_palettes/1)
  end

  defp priv_palette_files do
    app_paths =
      case :code.priv_dir(:blendend_playground) do
        {:error, _} -> []
        dir when is_list(dir) or is_binary(dir) -> [dir]
      end

    project_priv = Path.expand("priv", File.cwd!())
    search_roots = Enum.uniq([project_priv | app_paths])

    search_roots
    |> Enum.flat_map(fn root ->
      Path.wildcard(Path.join([root, "palettes", "*.json"]))
    end)
  end

  defp load_file_palettes(path) do
    with {:ok, body} <- File.read(path),
         {:ok, data} <- Jason.decode(body) do
      normalize_palettes(data, Path.basename(path, ".json"))
    else
      err ->
        IO.warn("failed to load palette file #{path}: #{inspect(err)}")
        []
    end
  end

  defp normalize_palettes(data, default_source)

  defp normalize_palettes(data, default_source) when is_list(data) do
    Enum.flat_map(data, fn
      %{"colors" => colors} = m when is_list(colors) ->
        name = Map.get(m, "name", "palette_#{System.unique_integer([:positive])}")
        source = Map.get(m, "source", default_source)

        [
          %Scheme{
            name: name,
            colors: colors,
            background: Map.get(m, "background"),
            stroke: Map.get(m, "stroke"),
            source: source
          }
        ]

      _ ->
        []
    end)
  end

  defp normalize_palettes(data, default_source) when is_map(data) do
    data
    |> Enum.flat_map(fn {name, value} ->
      cond do
        is_list(value) ->
          [
            %Scheme{
              name: to_string(name),
              colors: value,
              source: default_source
            }
          ]

        is_map(value) ->
          [
            %Scheme{
              name: to_string(name),
              colors: Map.get(value, "colors", []),
              background: Map.get(value, "background"),
              stroke: Map.get(value, "stroke"),
              source: Map.get(value, "source", default_source)
            }
          ]

        true ->
          []
      end
    end)
  end

  defp normalize_palettes(_data, _default_source), do: []
end
