# Port of https://generated.space/sketch/watercolor-2/
# https://github.com/kgolid/p5ycho/blob/master/horizon3/sketch.js
# by kgolid

defmodule BlendendPlaygroundPhx.Demos.Watercolor2 do
  @default_initial_size 5
  @default_initial_deviation 300.0
  @default_deviation 90.0
  @default_interpolate_passes 6
  @default_update_passes 5

  def init_points(width, ypos, opts \\ []) do
    initial_size = Keyword.get(opts, :initial_size, @default_initial_size) |> max(1)
    initial_deviation = Keyword.get(opts, :initial_deviation, @default_initial_deviation)
    interpolate_passes = Keyword.get(opts, :interpolate_passes, @default_interpolate_passes)

    denom = max(initial_size - 1, 1)

    points =
      for i <- 0..(initial_size - 1) do
        x = i / denom * width
        {x, ypos * 1.0, rand_between(-1.0, 1.0)}
      end

    if interpolate_passes <= 0 do
      points
    else
      Enum.reduce(1..interpolate_passes, points, fn _, acc ->
        interpolate(acc, initial_deviation)
      end)
    end
  end

  def update_xy(points, opts \\ []) do
    update_passes = Keyword.get(opts, :update_passes, @default_update_passes)
    deviation = Keyword.get(opts, :deviation, @default_deviation)

    if update_passes <= 0 do
      Enum.map(points, fn {x, y, _z} -> {x, y} end)
    else
      # `update_passes` independent gaussian perturbations combine into one with
      # stdev * sqrt(update_passes).
      effective_deviation = deviation * :math.sqrt(update_passes * 1.0)
      Enum.map(points, &move_nearby_xy(&1, effective_deviation))
    end
  end

  defp interpolate([first, second | rest], sd) do
    {rev, _last} =
      Enum.reduce([second | rest], {[first], first}, fn p2, {acc, p1} ->
        mid = generate_midpoint(p1, p2, sd)
        {[p2, mid | acc], p2}
      end)

    rev
  end

  defp interpolate(points, _sd), do: points

  defp generate_midpoint({x1, y1, z1}, {x2, y2, z2}, sd) do
    x = (x1 + x2) / 2.0
    y = (y1 + y2) / 2.0
    z = (z1 + z2) / 2.0 * 0.45 * rand_between(0.1, 3.5)
    move_nearby({x, y, z}, sd)
  end

  defp move_nearby({_, _, _} = pnt, sd) when sd == 0 or sd == 0.0, do: pnt

  defp move_nearby({x, y, z}, sd) do
    {x, y} = jitter_xy(x, y, z, sd)
    {x, y, z}
  end

  defp move_nearby_xy({x, y, _z}, sd) when sd == 0 or sd == 0.0, do: {x, y}

  defp move_nearby_xy({x, y, z}, sd) do
    jitter_xy(x, y, z, sd)
  end

  defp rand_between(min, max), do: min + :rand.uniform() * (max - min)

  defp rand_gaussian(mean, stdev) when stdev == 0 or stdev == 0.0, do: mean

  defp rand_gaussian(mean, stdev) do
    mean + :rand.normal() * stdev
  end

  defp jitter_xy(x, y, z, sd) do
    stdev = abs(z * sd)
    {rand_gaussian(x, stdev), rand_gaussian(y, stdev)}
  end
end

alias BlendendPlaygroundPhx.Demos.Watercolor2

width = 1500
height = 1000

draw width, height do
  clear(fill: rgb(0xFF, 0xFA, 0xCE))

  canvas = get_canvas()

  Enum.each(-100..(height - 1)//250, fn ypos ->
    points = Watercolor2.init_points(width, ypos)

    hue = :rand.uniform() * 360.0
    fill_color = hsv(hue, 1, 0.8)

    Enum.each(1..42, fn _ ->
      current = Watercolor2.update_xy(points)

      Blendend.Canvas.Fill.polygon(canvas, current,
        fill: fill_color,
        alpha: 0.01,
        comp_op: :darken
      )
    end)
  end)
end
