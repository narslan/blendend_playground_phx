# Dump font and text metrics.

alias Blendend.Text.{Face, Font, GlyphBuffer, GlyphRun}
# A4 Size
width = 1500
height = 1500

draw width, height do
  font_bold = font("AlegreyaSans", 60.0, "Bold")
  font_debug = font("Maplemono", 52.0)

  fm = Font.metrics!(font_bold)
  DebugLayout.log_font_metrics(fm, font_debug)
  canvas = Blendend.Draw.get_canvas()

  text = """
  Hello from blendend!
  """
MultilineLayout.schreib(canvas, font_bold, fm, text)
end
