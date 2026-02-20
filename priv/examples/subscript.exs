# Text.Multiline Example on https://fiddle.blend2d.com/.
# Shapes and centers multiple lines manually using Font metrics and GlyphRun.fill!/5.

alias Blendend.Text.{Face, Font, GlyphBuffer, GlyphRun}
# A4 Size
width = 1500
height = 1500

defmodule Debug do
  def log_metrics(fm, font_debug_metrics) do
    Enum.reduce(fm, 0, fn {k, v}, acc ->
      formatted = format_value(v)
      text(font_debug_metrics, 610, 520 + acc, "#{k} #{formatted}", fill: rgb(5, 15, 55))
      acc + 40
    end)
  end
  defp format_value(v) when is_float(v),
    do: :erlang.float_to_binary(v, decimals: 2)

  defp format_value(v),
    do: to_string(v)
end

defmodule MultilineLayout do
  def schreib(canvas, font, fm, text) do
    lines = String.split(text, "\n", trim: true)
    num_lines = length(lines)
    {width, height}= {1500, 1500}
    {w, h} = { width, height * 0.2}

    start_y = (h - num_lines * fm["size"] + fm["ascent"]) / 2.0

    line_height = fm["ascent"] + fm["descent"] + fm["line_gap"]

    fill_style = Blendend.Style.Color.rgb!(140, 25, 25)

    Enum.reduce(lines, start_y, fn line, y ->
      gb =
        GlyphBuffer.new!()
        |> GlyphBuffer.set_utf8_text!(line)
        |> Font.shape!(font)

      gr = Blendend.Text.GlyphRun.new!(gb)

      tm = Font.get_text_metrics!(font, gb)

      x = (w - (tm["bbox_x1"] - tm["bbox_x0"])) / 2.0

      GlyphRun.fill!(canvas, font, x, y, gr, fill: fill_style)

      y + line_height
    end)
  end
end

draw width, height do
  font_bold = font("AlegreyaSans", 60.0, "Bold")
  font_debug = font("AlegreyaSans", 52.0)

  fm = Font.metrics!(font_bold)
  fm_debug = Font.metrics!(font_debug)

  Debug.log_metrics(fm, font_debug)
  canvas = Blendend.Draw.get_canvas()

  text = """
  Hello from blendend!
  This is a simple multiline text example
  that uses BLGlyphBuffer and Fill.glyph_run!   
  """
MultilineLayout.schreib(canvas, font_bold, fm, text)
end
