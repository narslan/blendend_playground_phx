# This example demonstrates how to style glyphs one by one.
# Shapes a string, walks glyph advances, and 
# draws each outline with its own color.
alias Blendend.Text.{Face, Font, GlyphBuffer, GlyphRun}
alias Blendend.{Canvas, Style, Matrix2D, Draw, Path}

draw 800, 400 do
 
  text_string = "Αα, Ββ, Γγ, Δδ, Εε, Ζζ, Θθ"
  # 1) Load face + font
  face = Face.load!("priv/fonts/Alegreya-Regular.otf")
  size = 60.0
  font = Font.create!(face, size)
  canvas = Draw.get_canvas()
  # 2) baseline where utf8_text would draw
  baseline_x = 100.0
  baseline_y = 250.0
  # Reference: normal text draw
  text font, baseline_x, baseline_y - 100, text_string, fill: rgb(255, 255, 255) 
  # 3) design metrics -> scale
  {:ok, dm} = Face.design_metrics(face)
  upem = dm["units_per_em"] 
  scale = size / upem
  # 4) Shape + extract advances (design units)
  gb =
    GlyphBuffer.new!()
    |> GlyphBuffer.set_utf8_text!(text_string)
    |> Font.shape!(font)

  {glyph_infos, _total_advance} = GlyphRun.new!(gb)
                                 |> GlyphRun.inspect_run!()
                                 |> Enum.map(fn
      {:glyph, gid, {:advance_offset, {adv_x, _adv_y}, _off}} ->
        %{gid: gid, adv: adv_x}

      {:glyph, gid, _placement} ->
        # fallback: no explicit advance info – treat as zero 
        %{gid: gid, adv: 0.0}
    end)
    |> Enum.map_reduce(0.0, fn g, acc ->
      {g, acc + g.adv}
    end)
  
 
  # glyph_infos = [%{gid: gid, adv: adv}, ...]
  # 5) Draw via glyph outlines using scaled advances
  Enum.reduce(glyph_infos, 0.0, fn %{gid: gid, adv: adv}, pen_before ->
    # pen in *user* space
    pen_x_user = pen_before * scale
    gx = baseline_x + pen_x_user
    gy = baseline_y
    m =
      Matrix2D.identity!()
      |> Matrix2D.translate!(gx, gy)
    path = Path.new!()
    :ok = Font.get_glyph_outlines!(font, gid, m, path)
    Canvas.Fill.path(canvas, path, fill: Blendend.Style.Color.random())
    pen_before + adv
  end)
end
