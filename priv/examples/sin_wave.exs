# Plots sin(x) and 0.5*cos(2x) on a shared frame
w = 600
h = 400
scale = 2
w = scale * w
h = scale * h

draw w, h do
  clear(fill: rgb(235, 235, 235))
  f1 = fn x -> :math.sin(x) end
  f2 = fn x -> 0.5 * :math.cos(2 * x) end
  x_min = -:math.pi()
  x_max = :math.pi()

  steps = 150

  sample_fun = fn fun ->
    for i <- 0..steps do
      x = x_min + (x_max - x_min) * i / steps
      {x, fun.(x)}
    end
  end

  pts1 = sample_fun.(f1)
  pts2 = sample_fun.(f2)
  all_points = pts1 ++ pts2

  wave1_color = rgb(52, 120, 240)
  wave2_color = rgb(240, 120, 60)

  # Axes + labels
  {xs, ys} = Enum.unzip(all_points)
  {xmin, xmax} = {Enum.min(xs), Enum.max(xs)}
  {ymin, ymax} = {Enum.min(ys), Enum.max(ys)}
  pad = 0.08
  dx = max(xmax - xmin, 1.0e-6)
  dy = max(ymax - ymin, 1.0e-6)
  xmin = xmin - dx * pad
  xmax = xmax + dx * pad
  ymin = ymin - dy * pad
  ymax = ymax + dy * pad

  to_px = fn x, y ->
    sx = (x - xmin) / (xmax - xmin)
    sy = (ymax - y) / (ymax - ymin)
    {sx * (w - 1), sy * (h - 1)}
  end

  font = load_font("priv/fonts/Alegreya-Regular.otf", 22.0)

  axis_color = rgb(30, 30, 30)
  tick_color = rgb(90, 90, 90)
  label_color = rgb(40, 40, 40)

  polyline(Enum.map(pts1, fn {x, y} -> to_px.(x, y) end),
    stroke: wave1_color,
    stroke_width: 2.0
  )

  polyline(Enum.map(pts2, fn {x, y} -> to_px.(x, y) end),
    stroke: wave2_color,
    stroke_width: 2.0
  )

  ticks = fn min, max, count ->
    for i <- 0..count do
      min + (max - min) * i / count
    end
  end

  fmt_x = fn t ->
    cond do
      abs(t - :math.pi()) < 0.01 -> "π"
      abs(t + :math.pi()) < 0.01 -> "-π"
      abs(t) < 1.0e-4 -> "0"
      true -> :io_lib.format("~.1f", [t]) |> IO.iodata_to_binary()
    end
  end

  fmt_y = fn t ->
    cond do
      abs(t) < 1.0e-4 -> "0"
      true -> :io_lib.format("~.2f", [t]) |> IO.iodata_to_binary()
    end
  end

  is_zero = fn t -> abs(t) < 1.0e-6 end

  if ymin <= 0.0 and ymax >= 0.0 do
    {x0, y0} = to_px.(xmin, 0.0)
    {x1, _} = to_px.(xmax, 0.0)
    line(x0, y0, x1, y0, stroke: axis_color)
    # text font, x1 - 6, y0 + 16, "x", fill: axis_color

    ticks_x = for k <- -2..2, do: k * :math.pi() / 2

    for t <- ticks_x, t >= xmin and t <= xmax, not is_zero.(t) do
      {tx, ty} = to_px.(t, 0.0)
      line(tx, ty - 5, tx, ty + 5, stroke: tick_color)
      text(font, tx + 5, ty + 14, fmt_x.(t), fill: label_color)
    end
  end

  if xmin <= 0.0 and xmax >= 0.0 do
    {x0, y0} = to_px.(0.0, ymin)
    {_, y1} = to_px.(0.0, ymax)
    line(x0, y0, x0, y1, stroke: axis_color, stroke_width: 1.0)
    # text font, x0 + 6, y1 + 12, "y", fill: axis_color
    for t <- ticks.(ymin, ymax, 6), not is_zero.(t) do
      {tx, ty} = to_px.(0.0, t)
      line(tx - 4, ty, tx + 5, ty, stroke: tick_color)
      text(font, tx + 5, ty + 2, fmt_y.(t), fill: label_color)
    end
  end

  # Legend for the two series
  legend_w = 150.0
  legend_h = 48.0
  legend_x = w * 1.0 - legend_w - 12.0
  legend_y = 12.0
  round_rect(legend_x, legend_y, legend_w, legend_h, 6.0, 6.0, stroke: rgb(200, 200, 200))

  legend_entry = fn idx, label, color ->
    y = legend_y + 12.0 + idx * 18.0
    line(legend_x + 12.0, y, legend_x + 40.0, y, stroke: color, stroke_width: 2.0)
    text(font, legend_x + 48.0, y + 4.0, label, fill: label_color)
  end

  legend_entry.(0, "sin(x)", wave1_color)
  legend_entry.(1, "0.5 cos(2x)", wave2_color)
end
