defmodule BlendendPlaygroundPhx.FontPreview do
  @moduledoc """
  Render PNG previews for a font variation.
  """
  use Blendend.Draw

  @width 800
  @height 260

  def render(%{absolute_path: path, family: family, style: style} = variation, opts \\ %{}) do
    text = preview_text(variation, opts)
    size = preview_size(opts)
    {bg, fg, label_color} = preview_colors(opts)

    try do
      draw_result =
        draw @width, @height do
          clear(fill: bg)

          font = load_font(path, size)
          label_font = load_font(path, label_size(size))

          text(font, 36, @height * 0.58, text, fill: fg)

          meta = "#{family} · #{style}"
          text(label_font, 36, @height * 0.82, meta, fill: label_color)
        end

      case draw_result do
        {:ok, base64} -> {:ok, base64}
        {:error, reason} -> {:error, reason}
      end
    rescue
      e -> {:error, Exception.message(e)}
    end
  end

  defp preview_text(%{family: family, style: style}, %{"text" => text}) when is_binary(text) do
    text
    |> String.trim()
    |> present_or_default(family, style)
    |> decode_unicode_escapes()
  end

  defp preview_text(%{family: family, style: style}, %{text: text}) when is_binary(text) do
    text
    |> String.trim()
    |> present_or_default(family, style)
    |> decode_unicode_escapes()
  end

  defp preview_text(%{family: family, style: style}, _opts) do
    "#{family} #{style} · Aa Bb Cc 123"
  end

  defp present_or_default("", family, style),
    do: preview_text(%{family: family, style: style}, %{})

  defp present_or_default(value, _family, _style), do: value

  defp preview_size(%{"size" => size}), do: parse_size(size)
  defp preview_size(%{size: size}), do: parse_size(size)
  defp preview_size(_), do: 48.0

  defp parse_size(size) when is_binary(size) do
    case Float.parse(size) do
      {num, _} when num > 6 -> num
      _ -> 48.0
    end
  end

  defp parse_size(size) when is_number(size) and size > 6, do: size + 0.0
  defp parse_size(_), do: 48.0

  defp label_size(base_size) when is_number(base_size) do
    min(max(base_size * 0.45, 14.0), 28.0)
  end

  defp preview_colors(opts) do
    bg_hex = get_opt(opts, "bg") || "#0E0E10"
    fg_hex = get_opt(opts, "fg") || "#EEEEEE"

    {br, bg, bb} = parse_hex_rgb(bg_hex, {14, 14, 16})
    {fr, fg, fb} = parse_hex_rgb(fg_hex, {238, 238, 238})

    bg_color = rgb(br, bg, bb)
    fg_color = rgb(fr, fg, fb)

    label =
      rgb(
        mix_channel(fr, br, 0.45),
        mix_channel(fg, bg, 0.45),
        mix_channel(fb, bb, 0.45)
      )

    {bg_color, fg_color, label}
  end

  defp get_opt(opts, "bg") when is_map(opts), do: Map.get(opts, "bg") || Map.get(opts, :bg)
  defp get_opt(opts, "fg") when is_map(opts), do: Map.get(opts, "fg") || Map.get(opts, :fg)
  defp get_opt(_opts, _key), do: nil

  defp parse_hex_rgb(hex, fallback) when is_binary(hex) do
    hex = String.trim(hex)

    case hex do
      <<"#", r::binary-size(2), g::binary-size(2), b::binary-size(2)>> ->
        {String.to_integer(r, 16), String.to_integer(g, 16), String.to_integer(b, 16)}

      _ ->
        fallback
    end
  rescue
    _ -> fallback
  end

  defp parse_hex_rgb(_hex, fallback), do: fallback

  defp mix_channel(a, b, t) when is_number(t) do
    round(a * (1.0 - t) + b * t)
  end

  defp decode_unicode_escapes(text) when is_binary(text) do
    Regex.replace(~r/\\u\{([0-9A-Fa-f]{1,6})\}|\\u([0-9A-Fa-f]{4,6})/, text, fn match,
                                                                                braced,
                                                                                plain ->
      hex = if braced != "", do: braced, else: plain

      with {cp, ""} <- Integer.parse(hex, 16),
           true <- cp <= 0x10FFFF,
           false <- cp in 0xD800..0xDFFF do
        try do
          <<cp::utf8>>
        rescue
          _ -> match
        end
      else
        _ -> match
      end
    end)
  end
end
