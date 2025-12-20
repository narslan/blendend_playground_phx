width = 700
height = 480

draw width, height do
  label_font = load_font("priv/fonts/AlegreyaSans-Regular.otf", 14.0)
  mono_font = load_font("priv/fonts/MapleMono-Regular.otf", 12.0)

  draw_rect = fn x, y, w, h, color, label ->
    rect(x, y, w, h, fill: color)
    rect(x, y, w, h, mode: :stroke)
    text(mono_font, x + 4, y - 8, label, fill: rgb(40, 40, 50))
  end

  clear(fill: rgb(245, 245, 248))

  # coordinate axes for reference
  line(width * 0.5, 20, width * 0.5, height - 20, stroke: rgb(180, 180, 190))

  line(20, height * 0.5, width - 20, height * 0.5, stroke: rgb(180, 180, 190))

  # base rect
  base_x = width * 0.5
  base_y = height * 0.5
  rect_w = 120
  rect_h = 80

  # show origin dot
  circle(base_x, base_y, 4, fill: rgb(40, 40, 60))

  # reference rect (no transform)
  rect(base_x, base_y, rect_w, rect_h, fill: rgb(90, 160, 255, 120))

  draw_rect.(
    base_x,
    base_y,
    rect_w,
    rect_h,
    rgb(250, 10, 200, 100),
    "original"
  )

  # rotate around center via rotate_at
  cx = base_x + rect_w / 2
  cy = base_y + rect_h / 2

  rotate :math.pi() / 4, cx, cy do
    draw_rect.(
      base_x,
      base_y,
      rect_w,
      rect_h,
      rgb(100, 120, 200, 100),
      "rotate at center"
    )
  end

  cx = base_x
  cy = base_y
  # scale 
  m =
    matrix do
      translate(cx, cy)
      scale(2.5, 2.5)
      translate(-cx, -cy)
      post_translate(-rect_w / 2, -rect_h / 2)
      # rotate :math.pi/2, cx, cy
    end

  with_transform m do
    draw_rect.(cx, cy, rect_w, rect_h, rgb(25, 160, 120, 140), "scale")
  end

  # end
end
