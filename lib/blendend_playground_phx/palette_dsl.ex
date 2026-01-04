defmodule BlendendPlaygroundPhx.PaletteDSL do
  @moduledoc """
  Small helper API for palette-driven colors in sketches.

  This module is imported by `BlendendPlaygroundPhx.Renderer`, so examples under
  `priv/examples` can call:

    - `palette/1` or `palette/2` to fetch a scheme
    - `palette_first/1` / `palette_at/2` for cyclic access
    - `dark/1` and `hell/1` for darkest/lightest color (by luminance)
  """

  use Blendend.Draw

  alias BlendendPlaygroundPhx.Palette
  alias BlendendPlaygroundPhx.Palette.Scheme

  @doc "Fetch a palette scheme by name (supports `\"source.name\"`)."
  def palette(name), do: Palette.palette_by_name(name)

  @doc "Fetch a palette scheme by name + source."
  def palette(name, source), do: Palette.palette_by_name(name, source)

  @doc "Return the first palette color."
  def palette_first(palette), do: palette_at(palette, 0)

  @doc """
  Return the Nth palette color (cyclic).

  Accepts a `Scheme`, a map with `:colors`/`\"colors\"`, or a list of colors/hex strings.
  """
  def palette_at(palette, n) when is_integer(n) do
    colors = extract_colors(palette)

    if colors == [] do
      raise ArgumentError, "palette has no colors"
    end

    idx = cyclic_index(n, length(colors))
    colors |> Enum.at(idx) |> normalize_color!()
  end

  @doc "Return the darkest palette color (by relative luminance)."
  def dark(palette) do
    colors = extract_colors(palette)

    if colors == [] do
      raise ArgumentError, "palette has no colors"
    end

    colors
    |> Enum.map(&normalize_color!/1)
    |> Enum.min_by(&relative_luminance/1)
  end

  @doc "Return the lightest palette color (by relative luminance)."
  def hell(palette) do
    colors = extract_colors(palette)

    if colors == [] do
      raise ArgumentError, "palette has no colors"
    end

    colors
    |> Enum.map(&normalize_color!/1)
    |> Enum.max_by(&relative_luminance/1)
  end

  @doc "Apply an alpha channel (0..255) to a color/hex string."
  def alpha(color, a) when is_integer(a) do
    color = normalize_color!(color)
    {r, g, b, _} = Blendend.Style.Color.components!(color)
    rgb(r, g, b, a)
  end

  @doc """
  Fetch a named color from a scheme's categories (includes `\"stroke\"`/`\"background\"`).

  Returns `nil` when not found.
  """
  def palette_named(%Scheme{} = scheme, name) do
    key =
      case name do
        atom when is_atom(atom) -> Atom.to_string(atom)
        bin when is_binary(bin) -> String.trim(bin)
        other -> to_string(other)
      end

    case Map.get(scheme.categories || %{}, key) do
      nil -> nil
      hex -> normalize_color!(hex)
    end
  end

  def palette_named(_palette, _name), do: nil

  @doc """
  Draw a small on-canvas palette swatch card (useful for demos/debugging).

  Options:
    - `:at` `{x, y}` (required)
    - `:width` card width (default: 200)
    - `:max` max colors to show (default: 12)
    - `:chip` chip size (default: 16)
    - `:gap` vertical gap between rows (default: 8)
    - `:font` a font for labels (optional)
    - `:title` title string (optional)
    - `:highlights` list of indices to outline (optional)
  """
  def debug_palette_swatch(%Scheme{} = scheme, opts) when is_list(opts) do
    {x, y} = Keyword.fetch!(opts, :at)
    width = Keyword.get(opts, :width, 200) * 1.0
    max_colors = Keyword.get(opts, :max, 12)
    chip = Keyword.get(opts, :chip, 16) * 1.0
    gap = Keyword.get(opts, :gap, 8) * 1.0
    font = Keyword.get(opts, :font)
    highlights = Keyword.get(opts, :highlights, [])

    title =
      Keyword.get_lazy(opts, :title, fn ->
        source = scheme.source || "unknown"
        "Palette: #{source}.#{scheme.name}"
      end)

    pad = 12.0
    title_h = if is_nil(font) or is_nil(title), do: 0.0, else: 18.0

    colors = scheme.colors |> Enum.take(max_colors)
    row_h = chip + gap
    height = pad * 2 + title_h + length(colors) * row_h - gap

    round_rect(x, y, width, height, 16, 16,
      fill: rgb(255, 255, 255, 230),
      stroke: rgb(203, 213, 225, 220),
      stroke_width: 1.0
    )

    text_x = x + pad + chip + 10.0
    current_y = y + pad

    if font && title do
      text(font, x + pad, current_y + 12.0, title, fill: rgb(51, 65, 85))
    end

    start_y = current_y + title_h

    Enum.with_index(colors, fn hex, idx ->
      cy = start_y + idx * row_h
      color = normalize_color!(hex)

      rect(x + pad, cy, chip, chip, fill: color)

      if idx in highlights do
        rect(x + pad, cy, chip, chip, stroke: rgb(15, 23, 42), stroke_width: 2.0)
      else
        rect(x + pad, cy, chip, chip, stroke: rgb(148, 163, 184, 180), stroke_width: 1.0)
      end

      if font do
        text(font, text_x, cy + chip - 2.0, hex, fill: rgb(100, 116, 139))
      end
    end)

    :ok
  end

  defp extract_colors(%Scheme{colors: colors}) when is_list(colors), do: colors
  defp extract_colors(%{colors: colors}) when is_list(colors), do: colors
  defp extract_colors(%{"colors" => colors}) when is_list(colors), do: colors
  defp extract_colors(colors) when is_list(colors), do: colors
  defp extract_colors(_), do: []

  defp cyclic_index(n, len) when len > 0 do
    idx = rem(n, len)
    if idx < 0, do: idx + len, else: idx
  end

  defp normalize_color!(<<"#", _::binary>> = hex) do
    {r, g, b} = Palette.hex_to_rgb(hex)
    rgb(r, g, b)
  rescue
    _ -> raise ArgumentError, "invalid hex color: #{inspect(hex)}"
  end

  defp normalize_color!({r, g, b})
       when is_integer(r) and is_integer(g) and is_integer(b) do
    rgb(r, g, b)
  end

  defp normalize_color!({r, g, b, a})
       when is_integer(r) and is_integer(g) and is_integer(b) and is_integer(a) do
    rgb(r, g, b, a)
  end

  defp normalize_color!(other), do: other

  defp relative_luminance(color) do
    {r, g, b, _a} = Blendend.Style.Color.components!(color)

    r = srgb_to_linear(r / 255.0)
    g = srgb_to_linear(g / 255.0)
    b = srgb_to_linear(b / 255.0)

    0.2126 * r + 0.7152 * g + 0.0722 * b
  end

  defp srgb_to_linear(c) when c <= 0.04045, do: c / 12.92
  defp srgb_to_linear(c), do: :math.pow((c + 0.055) / 1.055, 2.4)
end
