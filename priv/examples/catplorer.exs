alias Blendend.Text.{Face, Font, GlyphBuffer, GlyphRun}
# A4 Size
width = 480
height = 1508

draw width, height do
  font = font("AlegreyaSans", 22.0, "Regular")
  fm = Font.metrics!(font)
  canvas = Blendend.Draw.get_canvas()

 atoms = Element.Query.where(
  atomic_number: {:<, 10}
) |> Element.Query.order_by(:atomic_number)
  num_lines = length(atoms)
  IO.inspect(num_lines)

  {w, h} = {width * 0.8, height * 0.2}

  start_y = (h - num_lines * fm["size"] + fm["ascent"]) / 2.0

  line_height = fm["ascent"] + fm["descent"] + fm["line_gap"]

  fill_style = Blendend.Style.Color.rgb!(140, 25, 25)



  Enum.reduce(atoms, start_y, fn line, y ->
    gb =
      GlyphBuffer.new!()
      |> GlyphBuffer.set_utf8_text!("#{line["name"]} #{line["atomic_radius"]}")
      |> Font.shape!(font)

    gr = Blendend.Text.GlyphRun.new!(gb)

    tm = Font.get_text_metrics!(font, gb)

    x = (w - (tm["bbox_x1"] - tm["bbox_x0"])) / 2.0

    GlyphRun.fill!(canvas, font, x, y, gr, fill: fill_style)

    y + line_height
  end)
end
