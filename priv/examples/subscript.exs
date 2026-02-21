# Text.Multiline Example on https://fiddle.blend2d.com/.
# Shapes and centers multiple lines manually using Font metrics and GlyphRun.fill!/5.
alias Blendend.Text.{Face, Font, GlyphBuffer, GlyphRun}
# A4 Size
width = 1500
height = 1500

draw width, height do
  font_bold = font("AlegreyaSans", 60.0, "Bold")
  font_debug = font("Dank Mono Regular", 52.0)

  fm = Font.metrics!(font_bold)
  fm_debug = Font.metrics!(font_debug)

  DebugLayout.log_font_metrics(fm, font_debug)
  canvas = Blendend.Draw.get_canvas()

  text = """
  Hello from blendendsd!
  """
MultilineLayout.schreib(canvas, font_bold, fm, text)
end
