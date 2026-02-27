# Shows how to pull design-space bounding boxes via Font.glyph_bounds!/2.
# Transforms them into user space and visualizes per-glyph extents next to the shaped run.

# Where we draw the run on the canvas
base_x = 40.0
base_y = 360.0

draw 1280, 1220 do
  clear(fill: rgb(20, 20, 20))

  font_bold = font("Maplemono", 22.0)
  font_debug_color = hsv(240, 0.1, 1)
  text = "NH3"

  face = Blendend.Text.Face.load!("priv/fonts/AlegreyaSans-Regular.otf")
  font_debug = Blendend.Text.Font.create_with_features!(face, 482.0, [{"subs", 1}])

  TextBoundLayout.inspect(font_debug, font_bold, text, base_x, base_y, font_debug_color)
end
