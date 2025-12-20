# Port of the demo https://openprocessing.org/sketch/1736173
# by the author takawo https://openprocessing.org/user/6533
use BlendendPlaygroundPhx.Calculation.Macros
alias BlendendPlaygroundPhx.Palette

defmodule BlendendPlaygroundPhx.Demos.Curtains do
  @deg_to_rad :math.pi() / 180.0

  defp deg_to_rad(deg), do: deg * @deg_to_rad

  def draw_brush_line(p1, p2, brush_size, palette) do
    # distance between two points
    len = dist(p1, p2) |> trunc()
    x0 = elem(p1, 0)
    y0 = elem(p1, 1)
    x1 = elem(p2, 0)
    y1 = elem(p2, 1)
    angle = atan2(y1 - y0, x1 - x0)
    angle_deg = angle * 180.0 / :math.pi()

    colors =
      palette
      |> Stream.cycle()
      |> Enum.take(5)

    seed_arr =
      0..4
      |> Enum.map(fn _ -> :rand.uniform(100_000) end)

    m =
      matrix do
        translate(x0, y0)
        rotate(angle)
      end

    with_transform m do
      l_freq = Enum.random([1, 2, 3, 4, 8, 16])
      noise_seed = List.last(seed_arr)

      if len > 0 do
        Enum.each(0..(len - 1), fn l ->
          grad_angle = deg_to_rad(l / len * (2 * :math.pi()) * l_freq)
          grad_cx = :math.cos(deg_to_rad(angle_deg))
          grad_cy = :math.sin(deg_to_rad(l + angle_deg)) * brush_size / 4.0
          grad = Blendend.Style.Gradient.conic!(grad_cx, grad_cy, grad_angle)

          values =
            seed_arr
            |> Enum.with_index()
            |> Enum.map(fn {seed, i} ->
              v = noise2(i * 1.0, 0.5 * l / len, seed)
              {v, Enum.at(colors, i)}
            end)

          {min_num, max_num} =
            Enum.reduce(values, {1.0, 0.0}, fn {v, _color}, {mn, mx} ->
              {min(mn, v), max(mx, v)}
            end)

          denom = max(max_num - min_num, 1.0e-12)

          values
          |> Enum.map(fn {v, color} ->
            {(v - min_num) / denom, color}
          end)
          |> Enum.each(fn {stop, color} ->
            Blendend.Style.Gradient.add_stop(grad, stop, color)
          end)

          mat_line =
            matrix do
              translate(l, :math.sin(deg_to_rad(y0 + l / len * 180.0)) * brush_size * 2.0)
              rotate(deg_to_rad(l / len * 360.0))

              rot_noise =
                noise2(:math.sin(deg_to_rad(y0 + l / len * 360.0)), 0.0, noise_seed)

              rotate(deg_to_rad(rot_noise * 180.0))
            end

          n = noise2(y0 * 1.0, l / len, noise_seed)

          with_transform mat_line do
            line(0, -brush_size * n, 0, brush_size * n,
              stroke: grad,
              stroke_width: 2.0,
              stroke_cap: :square,
              comp_op: :color_burn
            )
          end
        end)
      end
    end
  end
end

width = 800
height = 800
alias BlendendPlaygroundPhx.Demos.Curtains

draw width, height do
  bg = hsv(0, 0, 0.9)
  clear(fill: bg)

  palette =
    Palette.fetch_random_palette("flourish")
    |> Map.get(:colors, [])
    |> Palette.from_hex_list_hsv()
    |> Enum.map(fn {h, s, v} -> hsv({h, s, v, 127}) end)
    |> Enum.shuffle()

  offset = div(width, 10)

  Stream.iterate(0, &(&1 + offset))
  |> Stream.take_while(&(&1 < height))
  |> Enum.each(fn y ->
    brush_size = offset * Enum.random([1, 2.5, 1.5])
    p1 = {-offset, y}
    p2 = {width + offset, y}
    Curtains.draw_brush_line(p1, p2, brush_size, palette)
  end)
end
