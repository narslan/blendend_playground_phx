# Shows how to pull design-space bounding boxes via Font.glyph_bounds!/2.
# Transforms them into user space and visualizes per-glyph extents next to the shaped run.
alias Blendend.Text.{Font, GlyphBuffer, GlyphRun}

font = font("Alegreya", 80.0)
text = "blendend"

run =
  GlyphBuffer.new!()
  |> GlyphBuffer.set_utf8_text!(text)
  |> Font.shape!(font)
  |> GlyphRun.new!()

glyphs = GlyphRun.inspect_run!(run)

# extract ids in order
ids =
  for {:glyph, gid, _} <- glyphs do
    gid
  end

# Design-space bounding boxes for each gid: {x0_d, y0_d, x1_d, y1_d}
boxes_d = Font.glyph_bounds!(font, ids)

# Font matrix: design -> user
m = Font.matrix!(font)

to_user = fn {xd, yd} ->
  {
    m["m00"] * xd + m["m01"] * yd,
    m["m10"] * xd + m["m11"] * yd
  }
end

# Convert each (glyph, box_d) into a *user-space* box, using advances
boxes_u =
  Enum.zip(glyphs, boxes_d)
  |> Enum.map_reduce({0.0, 0.0}, fn
    {{:glyph, _gid, {:advance_offset, {ax, ay}, {px, py}}}, {x0_d, y0_d, x1_d, y1_d}},
    {pen_x, pen_y} ->
      # design-space origin of this glyph in the run
      origin_x = pen_x + px
      origin_y = pen_y + py

      # transform box corners to user space
      {ux0, uy0} = to_user.({origin_x + x0_d, origin_y + y0_d})
      {ux1, uy1} = to_user.({origin_x + x1_d, origin_y + y1_d})

      box_u = {ux0, uy0, ux1, uy1}
      new_pen = {pen_x + ax, pen_y + ay}

      {box_u, new_pen}
  end)
  |> elem(0)

# Where we draw the run on the canvas
base_x = 40.0
base_y = 140.0

draw 600, 220 do
  clear(fill: rgb(20, 20, 20))

  c = Blendend.Draw.get_canvas()

  # Draw the word
  GlyphRun.fill!(c, font, base_x, base_y, run, fill: rgb(230, 230, 230))

  # Draw each glyph's box (now aligned per glyph)
  boxes_u
  |> Enum.each(fn {ux0, uy0, ux1, uy1} ->
    box(
      base_x + ux0,
      base_y + uy0,
      base_x + ux1,
      base_y + uy1,
      stroke: Blendend.Style.Color.random(),
      stroke_width: 1.5
    )
  end)
end
