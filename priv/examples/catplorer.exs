alias Blendend.Text.{Face, Font, GlyphBuffer, GlyphRun}
# A4 Size
width = 480
height = 1508
{:ok, els} = Element.NDJSON.elements()
alias Explorer.DataFrame
draw width, height do
  font = font("AlegreyaSans", 22.0, "Regular")
  fm = Font.metrics!(font)
  canvas = Blendend.Draw.get_canvas()

   
  num_lines = DataFrame.n_rows(els)
IO.inspect(num_lines)
  {w, h} = {width * 0.8, height * 0.2}

  start_y = (h - num_lines * fm["size"] + fm["ascent"]) / 2.0

  line_height = fm["ascent"] + fm["descent"] + fm["line_gap"]

  fill_style = Blendend.Style.Color.rgb!(140, 25, 25)

    Enum.reduce(Explorer.Series.to_list(els["name"]), start_y, fn line, y ->
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
