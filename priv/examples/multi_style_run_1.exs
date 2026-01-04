# This example demonstrates how to style multiple glyphs via slicing
# Based on Text.Colorized example at https://fiddle.blend2d.com/
# Splits the shaped run into subranges and paints each slice with its own color.
alias Blendend.Text.{Face, Font, GlyphBuffer, GlyphRun}
alias Blendend.{Canvas, Style, Matrix2D, Draw, Path}

draw 800, 400 do
  clear(fill: rgb(0, 0, 0))
  font = font("Alegreya", 100.0)
  c = Draw.get_canvas()

  gr =
    GlyphBuffer.new!()
    |> GlyphBuffer.set_utf8_text!("Some sample text")
    |> Font.shape!(font)
    |> GlyphRun.new!()

  styles = [
    {5, rgb(255, 255, 255)},
    {5, rgb(255, 255, 0)},
    {6, rgb(255, 0, 0)}
  ]

  metrics = Font.metrics!(font)
  ascent = metrics["ascent"]
  margin = 10.0
  start_pt = {margin, margin + ascent}
  %{"m00" => sx, "m01" => sy} = Font.matrix!(font)

  Enum.reduce(styles, {0, start_pt}, fn {count, color}, {start, {x, y}} ->
    subrun = GlyphRun.slice!(gr, start, count)
    GlyphRun.fill!(c, font, x, y, subrun, fill: color)
    infos = GlyphRun.inspect_run!(subrun)

    {dx, dy} =
      Enum.reduce(infos, {0.0, 0.0}, fn
        {:glyph, _id, {:advance_offset, {ax, ay}, _off}}, {sx_acc, sy_acc} ->
          {sx_acc + ax * sx, sy_acc + ay * sy}

        _, acc ->
          acc
      end)

    {start + count, {x + dx, y + dy}}
  end)
end
