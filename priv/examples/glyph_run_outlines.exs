# Displays a single glyph as both filled text 
# and extracted outlines, color-coding vertex commands.

alias Blendend.Text.{Face, Font, GlyphBuffer, GlyphRun}
alias Blendend.{Canvas, Style, Matrix2D, Draw, Path}
draw 800, 800 do
  # 1) Background
  clear(fill: rgb(242, 233, 226))

  text_string = "A"

  # 2) Load font as usual
  face_alegreya = Blendend.Text.Face.load!("priv/fonts/Alegreya-Regular.otf")
  font_big = Blendend.Text.Font.create!(face_alegreya, 180.0)
  font_small = Blendend.Text.Font.create!(face_alegreya, 26.0)
  
  # 3) Draw normal text for reference
  baseline_x = 200.0
  baseline_y = 600.0

 
  # 4) Shape the text into a GlyphRun
  gb =
    Blendend.Text.GlyphBuffer.new!()
    |> Blendend.Text.GlyphBuffer.set_utf8_text!(text_string)
    |> Blendend.Text.Font.shape!(font_big)

  run = Blendend.Text.GlyphRun.new!(gb)

  # 5) Build a transform for the outlines:
  #    - translate so the text sits roughly at (40, baseline_y)
  m = matrix do
    translate(baseline_x, baseline_y)
    scale(4,4)
  end  

  # 6) Extract glyph outlines into a Path
  path = Blendend.Path.new!()
  :ok = Blendend.Text.Font.get_glyph_run_outlines(font_big, run, m, path)

  # 7) Stroke the outlines in a different color
  outlines_color = rgb(200, 230, 30, 255)

  stroke_path path, fill: outlines_color

  # 8) Inspect the path vertices in the log
  count = Blendend.Path.vertex_count!(path)
  style_close = hsv(168, 0.40, 0.57)
  style_move  = hsv(30, 0.2, 0.48)
  style_line  = hsv(3, 0.75, 0.87)
  style_cubic = rgb(0, 0, 255)
  style_quad  = rgb(90, 90, 255)
  style_text = rgb(44, 40,37)
  0..(count - 1)
  |> Enum.each(fn i ->
    {cmd, x, y }= Blendend.Path.vertex_at!(path, i)
    case cmd do
      :close ->    circle x, y, 5, fill: style_close
      :move_to ->  circle x, y, 6, stroke: style_move
      :line_to ->  triangle x, y, 12, fill: style_line
      :cubic_to -> circle x, y, 4, fill: style_cubic
      :quad_to ->  circle x, y, 3, fill: style_quad
    end
  end)
text font_small, 600, 200, "close", fill: style_text
text font_small, 600, 220, "move_to", fill: style_text 
text font_small, 600, 240, "line_to", fill: style_text
text font_small, 600, 260, "cubic_to", fill: style_text
text font_small, 600, 280, "quad_to", fill: style_text
circle 720, 195, 5, fill: style_close
circle 720, 215, 6, stroke: style_move
triangle 720, 235, 12, fill: style_line
circle 720, 255, 4, fill: style_cubic
circle 720, 275, 3, fill: style_quad 
end
