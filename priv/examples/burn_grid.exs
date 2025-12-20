# Port of https://openprocessing.org/sketch/855987 to blendend.
# Exercises blend modes (burn), gradients, and soft blur.
alias BlendendPlaygroundPhx.Palette

defmodule BlendendPlaygroundPhx.Demos.BurnGrid do
  def noise_overlay(w, h) do
    points =
      for _ <- 1..round(w * h * 0.1) do
        {:rand.uniform(w), :rand.uniform(h), :rand.uniform() * 0.6}
      end

    fn ->
      Enum.each(points, fn {x, y, weight} ->
        circle(x, y, weight, fill: rgb(255, 255, 255, 200))
      end)
    end
  end

  def to_path(points) do
    {path, started?} =
      Enum.reduce(points, {Blendend.Path.new!(), false}, fn {x, y}, {p, started?} ->
        if started? do
          {Blendend.Path.line_to!(p, x, y), true}
        else
          {Blendend.Path.move_to!(p, x, y), true}
        end
      end)

    if started?, do: Blendend.Path.close!(path), else: path
  end
end

w = 800
h = 800
alias BlendendPlaygroundPhx.Demos.BurnGrid, as: Demo

palette =
  Palette.palette_by_name("artists.burn_grid_demo")
  |> Map.get(:colors, [])
  |> Palette.from_hex_list_hsv()
  |> Enum.map(fn {h, s, v} -> hsv(h, s, v) end)

noise = Demo.noise_overlay(w, h)

draw w, h do
  # base background
  clear(fill: hsv(:rand.uniform(360), 0.05, 0.95))
  layers = 5

  for _k <- 1..layers do
    offset = w / 15
    cells = :rand.uniform(10) + 1
    margin = 0
    d = (w - offset * 2 - margin * (cells - 1)) / cells

    for j <- 0..(cells - 1), i <- 0..(cells - 1) do
      x = offset + i * (d + margin)
      y = offset + j * (d + margin)

      translate x + d / 2, y + d / 2 do
        rotate(:rand.uniform(4) * :math.pi() / 2)

        if :rand.uniform(100) > 33 do
          [c1, c2, c3] = Enum.take_random(palette, 3)

          grad =
            radial_gradient -d / 2, -d / 2, 0, -d / 2, -d / 2, d * 2 do
              add_stop(0.0, c1)
              add_stop(0.5, c2)
              add_stop(1.0, c3)
            end

          rand_shape = :rand.uniform(100)

          shape =
            cond do
              rand_shape > 70 ->
                [{-d / 2, -d / 2}, {0, -d / 2}, {d / 2, d / 2}, {0, d / 2}]

              rand_shape > 30 and rand_shape < 70 ->
                [{d / 2, -d / 2}, {0, -d / 2}, {-d / 2, d / 2}, {0, d / 2}]

              true ->
                [{-d / 2, -d / 2}, {d / 2, -d / 2}, {d / 2, d / 2}]
            end

          path = Demo.to_path(shape)
          random_color = Enum.random(palette)

          polygon(shape, fill: grad, comp_op: :color_burn)

          shadow_path(path, 1.0, 1.0, w / 40.0, fill: random_color, resolution: 0.1)
        end
      end
    end
  end

  noise.()
end
