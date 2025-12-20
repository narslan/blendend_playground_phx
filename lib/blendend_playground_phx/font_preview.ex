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

    try do
      draw_result =
        draw @width, @height do
          clear(fill: rgb(14, 14, 16))

          font = load_font(path, size)
          label_font = load_font(path, label_size(size))

          text(font, 36, @height * 0.58, text, fill: rgb(238, 238, 238))

          meta = "#{family} · #{style}"
          text(label_font, 36, @height * 0.82, meta, fill: rgb(170, 170, 170))
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
    present_or_default(String.trim(text), family, style)
  end

  defp preview_text(%{family: family, style: style}, %{text: text}) when is_binary(text) do
    present_or_default(String.trim(text), family, style)
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
end
