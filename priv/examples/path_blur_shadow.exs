# Shape-aware blur + shadow demo (Blendend.Effects.blur_path/4).
draw 720, 420 do
  clear(fill: rgb(100, 14, 18))
  font = font("Alegreya", 16.0)

  path ring do
    add_circle(220, 210, 96.0)
    close()
  end

  path star do
    move_to(460, 110)
    line_to(500, 190)
    line_to(585, 200)
    line_to(515, 250)
    line_to(535, 330)
    line_to(460, 285)
    line_to(385, 330)
    line_to(405, 250)
    line_to(335, 200)
    line_to(420, 190)
    close()
  end

  # Soft shadow and glow on the ring
  shadow_path(ring, 14.0, 12.0, 36.0, fill: rgb(0, 0, 0, 180))

  blur_path(ring, 2.6,
    mode: :stroke,
    stroke: rgb(90, 200, 255),
    stroke_width: 10.0
  )

  fill_path(ring, fill: rgb(30, 120, 210))
  stroke_path(ring, stroke: rgb(230, 245, 255), stroke_width: 2.5)

  # Bright shape with offset glow
  shadow_path(star, 10.0, 8.0, 15.0, fill: rgb(250, 0, 0, 150))

  blur_path(star, 1.8,
    mode: :fill_and_stroke,
    fill: rgb(255, 110, 180),
    stroke: rgb(255, 200, 230),
    stroke_width: 4.0
  )

  fill_path(star, fill: rgb(40, 190, 170))
  stroke_path(star, stroke: rgb(240, 255, 255), stroke_width: 2.5)

  text(font, 22, 34, "Shape blur & soft shadows (Blendend.Effects)", fill: rgb(225, 230, 236))

  text(font, 22, 56, "Options: mode, offset; styles mirror fill/stroke.",
    fill: rgb(180, 190, 200)
  )
end
