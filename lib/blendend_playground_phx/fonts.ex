defmodule BlendendPlaygroundPhx.Fonts do
  @moduledoc """
  Keeps a lightweight ETS registry of available fonts under `priv/fonts`
  plus optional extra search paths (e.g. `~/.fonts`).

  Entries are grouped by family and expose their variations (style/weight)
  alongside filesystem paths so other parts of the app can look up the right
  face and hand its path to `Blendend.load_font/2`.
  """
  use GenServer

  @table :blendend_fonts
  @font_exts ~w(.otf .ttf)

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  List all registered font families with their variations.
  """
  def all do
    ensure_table()

    @table
    |> :ets.tab2list()
    |> Enum.filter(fn {key, _} -> match?({:family, _}, key) end)
    |> Enum.map(fn {_key, font} -> font end)
    |> Enum.sort_by(& &1.family)
  end

  @doc """
  Fetch a family by slug or family name.
  """
  def get(id) when is_binary(id) do
    case :ets.lookup(@table, {:family, normalize_id(id)}) do
      [{{:family, _}, font}] -> {:ok, font}
      [] -> {:error, :not_found}
    end
  end

  @doc """
  Lookup a specific face within a family. Optional style narrows the choice,
  otherwise the first variation is returned.
  """
  def lookup(id, style \\ nil) do
    with {:ok, font} <- get(id),
         variation when not is_nil(variation) <- pick_variation(font.variations, style) do
      {:ok, variation}
    else
      _ -> {:error, :not_found}
    end
  end

  def refresh, do: GenServer.call(__MODULE__, :refresh)

  # Server callbacks

  @impl true
  def init(_opts) do
    tid = ensure_table()
    load_fonts()
    {:ok, %{table: tid}}
  end

  @impl true
  def handle_cast(:refresh, state) do
    load_fonts()
    {:noreply, state}
  end

  @impl true
  def handle_call(:refresh, _from, state) do
    load_fonts()
    {:reply, :ok, state}
  end

  # Helpers

  defp ensure_table do
    case :ets.whereis(@table) do
      :undefined -> :ets.new(@table, [:set, :public, :named_table, read_concurrency: true])
      tid -> tid
    end
  end

  defp load_fonts do
    table = ensure_table()
    :ets.delete_all_objects(table)

    {priv_fonts, extra_paths} = font_paths()
    File.mkdir_p!(priv_fonts)

    faces =
      [priv_fonts | extra_paths]
      |> Enum.flat_map(&list_font_files/1)
      |> Enum.map(&build_face(&1, priv_fonts))

    faces
    |> Enum.group_by(& &1.family)
    |> Enum.each(fn {family, family_faces} ->
      id = slugify(family)

      variations =
        Enum.map(family_faces, fn face ->
          %{
            id: face.id,
            family: face.family,
            style: face.style,
            weight: face.weight,
            path: face.path,
            absolute_path: face.absolute_path
          }
        end)
        |> Enum.sort_by(& &1.weight)

      entry = %{id: id, family: family, variations: variations}
      :ets.insert(table, {{:family, id}, entry})
    end)

    :ok
  end

  defp list_font_files(root) do
    root = Path.expand(root)

    if File.dir?(root) do
      root
      |> Path.join("**/*")
      |> Path.wildcard(match_dot: true)
      |> Enum.filter(&File.regular?/1)
      |> Enum.filter(&font_file?/1)
    else
      []
    end
  end

  defp font_file?(file) do
    ext = file |> Path.extname() |> String.downcase()
    ext in @font_exts
  end

  defp build_face(file, priv_fonts_dir) do
    base = file |> Path.basename() |> Path.rootname()
    {family, style} = split_family_style(base)
    face_id = slugify(base)
    abs_path = Path.expand(file)
    display_path = display_path(abs_path, priv_fonts_dir)

    %{
      id: face_id,
      family: family,
      style: style,
      weight: weight_from_style(style),
      path: display_path,
      absolute_path: abs_path
    }
  end

  defp display_path(abs_path, priv_fonts_dir) do
    cond do
      String.starts_with?(abs_path, priv_fonts_dir) ->
        "priv/fonts/" <> Path.relative_to(abs_path, priv_fonts_dir)

      true ->
        case Path.relative_to_cwd(abs_path) do
          ^abs_path -> abs_path
          rel -> rel
        end
    end
  end

  defp split_family_style(base) do
    case String.split(base, "-", parts: 2) do
      [family, style] -> {humanize(family), humanize(style)}
      [family] -> {humanize(family), "Regular"}
    end
  end

  defp pick_variation([], _style), do: nil
  defp pick_variation(variations, nil), do: hd(variations)

  defp pick_variation(variations, style) when is_binary(style) do
    style_down = String.downcase(style)

    Enum.find(variations, fn var ->
      String.downcase(var.style) == style_down
    end) || pick_variation(variations, nil)
  end

  defp font_paths do
    priv_fonts =
      case :code.priv_dir(:blendend_playground_phx) do
        {:error, _} -> Path.expand("priv/fonts", File.cwd!())
        path -> Path.join(to_string(path), "fonts")
      end

    home_fonts =
      case System.get_env("HOME") do
        nil -> nil
        home -> Path.join(home, ".fonts")
      end

    configured = Application.get_env(:blendend_playground_phx, :font_paths, [])

    extras =
      configured
      |> List.wrap()
      |> Enum.map(&Path.expand/1)
      |> Enum.reject(&is_nil/1)

    {priv_fonts, [home_fonts | extras] |> Enum.reject(&is_nil/1) |> Enum.uniq()}
  end

  defp weight_from_style(style) do
    case String.downcase(style) do
      "thin" -> 100
      "extralight" -> 200
      "light" -> 300
      "regular" -> 400
      "medium" -> 500
      "semibold" -> 600
      "bold" -> 700
      "extrabold" -> 800
      "black" -> 900
      _ -> 400
    end
  end

  defp humanize(string) do
    string
    |> String.replace("_", " ")
    |> String.split(~r/[\s]+/)
    |> Enum.map(&capitalize_segment/1)
    |> Enum.join(" ")
  end

  defp capitalize_segment(<<first::utf8, rest::binary>>) do
    String.upcase(<<first::utf8>>) <> String.downcase(rest)
  end

  defp capitalize_segment(other), do: other

  defp normalize_id(id) do
    id
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
  end

  defp slugify(text) do
    text
    |> normalize_id()
  end
end
