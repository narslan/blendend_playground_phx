# Text.GlyphOutlines example on https://fiddle.blend2d.com/.
# Distorts glyph outline vertices with random jitter before filling the warped shape.
alias Blendend.Text.{Face, Font, GlyphBuffer, GlyphRun}
alias Blendend.{Canvas, Style, Matrix2D, Draw, Path}
draw 500, 140 do
  
  clear(fill: rgb(0, 0, 0))

  amount = 3.5
  text_string = "Path distortion!"
  font = load_font("priv/fonts/Alegreya-Regular.otf", 65.0)
   
  gr = GlyphBuffer.new!()
    |> GlyphBuffer.set_utf8_text!(text_string)
    |> Font.shape!(font)
    |> GlyphRun.new!()

  m = Matrix2D.identity!()
  path = Path.new!() |> Font.get_glyph_run_outlines!(font, gr, m)
  
  count = Blendend.Path.vertex_count!(path)

    for i <- 0..(count - 1) do
      case Blendend.Path.vertex_at(path, i) do
        {:ok, {"close", _x, _y}} ->
          :ok

        {:ok, {cmd, x, y}} ->
          dx = :rand.uniform() * (amount * 2.0) - amount
          dy = :rand.uniform() * (amount * 2.0) - amount
          Blendend.Path.set_vertex_at(path, i, :preserve, x + dx, y + dy)

        other ->
          IO.inspect({:unexpected_vertex, i, other})
      end
    end
  
   translate 15, 100 
   fill_path path, fill: rgb(255, 255, 255)
end

