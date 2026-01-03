# Port of https://openprocessing.org/sketch/1630344 to blendend.
# Staggered rows of clipped circles filled with layered petals.
defmodule BlendendPlaygroundPhx.Demos.FloralWave do
  alias BlendendPlaygroundPhx.Palette

  def pick_palette do
    Palette.fetch_random_source()
    |> Palette.fetch_random_palette()
    |> Map.get(:colors, [])
    |> Palette.from_hex_list_rgb()
    |> Enum.map(&rgb/1)
  end

  defp draw_flower(x, y, r_max, r_step, colors, base) do
    translate x, y do
      Enum.reduce_while(
        Stream.iterate(r_max, &(&1 - r_step)),
        0,
        fn r, idx ->
          if r <= r_max / 5,
            do: {:halt, idx},
            else: {:cont, petal_ring(r, r_max, colors, idx)}
        end
      )

      # most inner circle
      circle(0.0, 0.0, r_max / 5, fill: base)
      circle(0.0, 0.0, r_max / 5, stroke: rgb(0, 0, 0, 200))
    end
  end

  defp petal_ring(r, r_max, colors, idx0) do
    petals = :rand.uniform(26) + 4
    angle_step = 2 * :math.pi() / petals
    rotation = :math.pi() * r / r_max

    Enum.reduce(0..(petals - 1), idx0, fn p_idx, acc ->
      angle = p_idx * angle_step + rotation
      x1 = :math.cos(angle) * r
      y1 = :math.sin(angle) * r
      x2 = :math.cos(angle + angle_step) * r
      y2 = :math.sin(angle + angle_step) * r
      x = (x1 + x2) / 2
      y = (y1 + y2) / 2
      d = :math.sqrt(:math.pow(x1 - x2, 2) + :math.pow(y1 - y2, 2))
          
      petal_color = Enum.at(colors, rem(acc, 2))       
      petal_arc(x, y, d, petal_color)
      acc + 1
    end)
  end

  defp petal_arc(cx, cy, r, color) do
    # steps = 16
    start_angle = :math.atan2(cy, cx) - :math.pi() / 2
    end_angle = :math.atan2(cy, cx) + :math.pi() / 2
    step = :math.pi() / 180

    points =
      Stream.iterate(start_angle, &(&1 + step))
      |> Stream.take_while(&(&1 <= end_angle))
      |> Enum.map(fn angle ->
        {cx + :math.cos(angle) * r / 2, cy + :math.sin(angle) * r / 2}
      end)

    polygon([{0.0, 0.0} | points], fill: color)
    polyline([{0.0, 0.0} | points], stroke: rgb(0, 0, 0))
  end

  def layer_circle(x, y, d, palette) do
    [base | petal_colors] = Enum.shuffle(palette)

    base_r = d / 2

    # subtle shadow/glow: lighter alpha and smaller blur radius
    blur_path(circle_path(x, y, base_r), base_r / 7,
      mode: :fill,
      fill: rgb(0, 0, 0, 100),
      padding: base_r / 2
    )

    # keep base disc crisp on top of the blur
    circle(x, y, base_r, fill: base)

    draw_flower(x, y, base_r / 1.5, base_r / 6.0, petal_colors, base)
  end

  defp circle_path(x, y, r) do
    Blendend.Path.new!() |> Blendend.Path.add_circle!(x, y, r)
  end

  def stream_scales(x, y, factor, max_w, fun) do
    if x <= max_w do
      fun.(x, y)
      stream_scales(x * factor, y * factor, factor, max_w, fun)
    end
  end
end

# ---------------------------------------------------------------------------
# Main sketch
# ---------------------------------------------------------------------------
w = 2800
h = 2800
alias BlendendPlaygroundPhx.Demos.FloralWave

draw w, h do
  palette = FloralWave.pick_palette()
  [bg | colors] = palette

  clear(fill: bg)
  clear(fill: rgb(0, 0, 0, 60), comp_op: :multiply)
  rows = 5
  offset = w / 5
  cell_h = (h - offset * 2) / rows
  max_w = w - offset * 2
  base_angle = :math.pi() / 180 * (180 / 12 + 7)

  Enum.each(0..rows, fn i ->
    ox = if rem(i, 2) == 0, do: offset, else: w - offset
    oy = offset + cell_h * i

    translate ox, oy do
      rot = if rem(i, 2) == 0, do: -base_angle / 2, else: -base_angle / 2 + :math.pi()

      rotate rot do
        x = 10.0
        y = x * :math.tan(base_angle / 2)
        d = :math.sqrt(x * x + y * y)
        scale_factor = (d + y) / (d - y)

        FloralWave.stream_scales(x, y, scale_factor, max_w, fn sx, sy ->
          FloralWave.layer_circle(sx, sy, sy * 2, colors)
        end)
      end
    end
  end)
end
