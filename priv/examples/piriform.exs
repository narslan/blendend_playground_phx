canvas_w = 800
canvas_h = 800

draw canvas_w, canvas_h do
  sample_parametric = fn fun, t0, t1, steps ->
    dt = (t1 - t0) / steps

    for i <- 0..steps do
      fun.(t0 + dt * i)
    end
  end

  a = 1.0
  b = 0.5

  pts_math =
    sample_parametric.(
      fn t ->
        x = a * (1.0 + :math.sin(t))
        y = b * :math.cos(t) * (1.0 + :math.sin(t))
        {-y, -x}
      end,
      0.0,
      2.0 * :math.pi(),
      400
    )

  scale = 240
  # Fit the math coordinates into the canvas with generous padding.
  points =
    Enum.map(pts_math, fn {x, y} ->
      {
        -x * scale + 400,
        -y * scale
      }
    end)

  grad =
    radial_gradient canvas_w * 0.5, canvas_h * 0.3, 200, canvas_w * 0.5, canvas_h * 0.3, 0 do
      add_stop(0.00, rgb(255, 225, 255, 250))
      add_stop(0.10, rgb(225, 210, 255))
      add_stop(1.00, rgb(60, 20, 120))
    end

  polygon(points, fill: grad)

  grad2 =
    linear_gradient canvas_w * 0.5,
                    canvas_h * 0.4,
                    canvas_w * 0.5 + canvas_w * 0.4,
                    canvas_h * 0.4 + canvas_h * 0.4 do
      add_stop(0.1, rgb(0xFF, 0xFF, 0xFF))
      add_stop(1.0, rgb(0x3F, 0x9F, 0xFF))
    end

  # Position the rounded rect offset from the piriform, similar to the Blend2D logo layout.
  round_rect(canvas_w * 0.5, canvas_h * 0.4, canvas_w * 0.4, canvas_h * 0.4, 40, 40,
    fill: grad2,
    comp_op: :difference
  )
end
