# Shows how to pull design-space bounding boxes via Font.glyph_bounds!/2.
# Transforms them into user space and visualizes per-glyph extents next to the shaped run.

# Where we draw the run on the canvas
base_x = 40.0
base_y = 340.0

draw 1280, 1220 do
  clear(fill: rgb(20, 20, 20))
  
  font_debug = font("AlegreyaSans", 482.0)
font_bold = font("Dank Mono Regular", 42.0)
font_debug_color = hsv(240, 0.1, 1)
  text = "nadr"
  TextBoundLayout.inspect(font_debug, font_bold, text, base_x, base_y, font_debug_color)
end
