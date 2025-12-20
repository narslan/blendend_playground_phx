defmodule BlendendPlaygroundPhx.Swatches do
  @moduledoc """
  Render color swatches + labels using Blendend.
  """
  use Blendend.Draw

  @cols_per_row 6
  @box 160
  @pad 40

  @doc """
  Render swatches from a palette. Expects a map with `"colors"` or `"values"`,
  or a list of color maps like `%{"hex" => "#rrggbb", "label" => "name"}`.
  """

  def render(%BlendendPlaygroundPhx.Palette.Scheme{} = scheme), do: do_render(scheme)

  defp do_render(%BlendendPlaygroundPhx.Palette.Scheme{} = scheme) do
    {width, height} = dims(scheme.colors)

    draw width, height do
      background_color =
        if scheme.background do
          {r, g, b} = hex_to_rgb(scheme.background)
          rgb(r, g, b)
        else
          rgb(245, 245, 245)
        end

      clear(fill: background_color)

      stroke_color =
        if scheme.stroke do
          {r, g, b} = hex_to_rgb(scheme.stroke)
          rgb(r, g, b)
        else
          rgb(0, 0, 0)
        end

      # {:ok, serif_face} = Blendend.Text.Face.load(priv_font_path("Alegreya-Regular.otf"))
      # {:ok, serif_regular} = Blendend.Text.Font.create(serif_face, 12.0)

      {:ok, monospace_face} =
        Blendend.Text.Face.load(priv_font_path("MapleMono-Regular.otf"))

      {:ok, monospace_regular} = Blendend.Text.Font.create(monospace_face, 12.0)

      {:ok, sans_face} = Blendend.Text.Face.load(priv_font_path("AlegreyaSans-Regular.otf"))
      {:ok, sans_regular} = Blendend.Text.Font.create(sans_face, 20.0)

      # IO.inspect(sans_regular)
      label = scheme.name |> String.replace("_", " ") |> String.capitalize()

      {rr, rb, bb, _} = Blendend.Style.Color.components!(background_color)
      {rs, gs, bs, _} = Blendend.Style.Color.components!(stroke_color)

      text(
        monospace_regular,
        width * 0.5,
        height * 0.05,
        "background (rgb): #{rr}, #{rb}, #{bb}",
        fill: stroke_color
      )

      text(
        monospace_regular,
        width * 0.5,
        height * 0.05 + 12,
        "stroke     (rgb): #{rs}, #{gs}, #{bs}",
        fill: stroke_color
      )

      text(sans_regular, width * 0.05, height * 0.05, label, fill: stroke_color)

      Enum.with_index(scheme.colors, fn color, idx ->
        row = div(idx, @cols_per_row)
        col = rem(idx, @cols_per_row)
        x = @pad + col * @box
        y = 2 * @pad + 2 * row * @box
        {r, g, b} = hex_to_rgb(color)
        {h, s, v} = BlendendPlaygroundPhx.Palette.hex_to_hsv(color)
        h_disp = round(h)
        s_disp = :erlang.float_to_binary(s, decimals: 2)
        v_disp = :erlang.float_to_binary(v, decimals: 2)
        rect(x, y, @box - @pad, @box - @pad + 10, fill: rgb(r, g, b))
        rect(x, y, @box - @pad, @box - @pad + 10, stroke: stroke_color, stroke_width: 0.1)

        text(monospace_regular, x, y + @box + @pad - 20, "hsv: #{h_disp}, #{s_disp}, #{v_disp}",
          fill: stroke_color
        )

        text(monospace_regular, x, y + @box + @pad, "rgb: #{r}, #{g}, #{b}", fill: stroke_color)

        BlendendPlaygroundPhx.Demos.EgyptianTombCeiling.flower(
          x + (@box - @pad) / 2,
          y + @box + 3 * @pad - 20,
          100,
          rgb(r, g, b)
        )
      end)
    end
  end

  def hex_to_rgb(<<"#", h::binary-size(6)>>) do
    <<r::binary-size(2), g::binary-size(2), b::binary-size(2)>> = h
    {String.to_integer(r, 16), String.to_integer(g, 16), String.to_integer(b, 16)}
  end

  defp priv_font_path(file) do
    otp_path =
      case :code.priv_dir(:blendend_playground) do
        {:error, _} -> nil
        path -> Path.join(path, "fonts/#{file}")
      end

    blendend_path =
      case :code.priv_dir(:blendend) do
        {:error, _} -> nil
        path -> Path.join(path, "fonts/#{file}")
      end

    project_path = Path.expand("priv/fonts/#{file}", File.cwd!())

    cond do
      otp_path && File.exists?(otp_path) -> otp_path
      blendend_path && File.exists?(blendend_path) -> blendend_path
      File.exists?(project_path) -> project_path
      true -> raise "font file not found: #{file}"
    end
  end

  defp dims(scheme) do
    count = length(scheme)
    rows = div(count + @cols_per_row - 1, @cols_per_row)
    width = @cols_per_row * @box + @pad * 2
    height = rows * @box + @pad * 12
    {width, height}
  end
end
