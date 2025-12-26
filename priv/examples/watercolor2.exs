# Port of https://generated.space/sketch/watercolor-2/
# https://github.com/kgolid/p5ycho/blob/master/horizon3/sketch.js
# by kgolid

defmodule BlendendPlaygroundPhx.Demos.Watercolor2 do
  @default_initial_size 5
  @default_initial_deviation 300.0
  @default_deviation 90.0
  @default_interpolate_passes 6
  @default_update_passes 5

  # Pick one to compare distributions with identical stdev scaling.
  # - :gaussian uses `Blendend.Rand.normal/0` (Normal(0, 1)).
  # - :uniform uses a scaled Uniform(-1, 1) (flat density).
  # - :triangular uses a scaled (U + U - 1) (closer to gaussian, no NIF).
  # - :perlin uses correlated 2D Perlin noise (FastNoise2) sampled from a precomputed grid.
  @jitter_dist :gaussian

  @default_noise_frequency 0.02
  @default_noise_seed 1337
  @default_noise_grid_w 512
  @default_noise_grid_h 512
  @default_noise_layer_shift 37.0

  def jitter_dist, do: @jitter_dist

  def perlin_node!(opts \\ []) do
    simd_level = Keyword.get(opts, :simd_level, 0)

    perlin_id =
      0..(FastNoise2.metadata_count() - 1)
      |> Enum.find_value(fn id ->
        if FastNoise2.metadata_name(id) == "Perlin", do: id
      end) || raise "FastNoise2 Perlin node not found"

    case FastNoise2.new_from_metadata(perlin_id, simd_level) do
      {:ok, node} -> node
      {:error, reason} -> raise "failed to create FastNoise2 Perlin node: #{inspect(reason)}"
    end
  end

  def perlin_samplers!(world_w, world_h, opts \\ []) do
    frequency = Keyword.get(opts, :frequency, @default_noise_frequency)
    seed_x = Keyword.get(opts, :seed_x, @default_noise_seed)
    seed_y = Keyword.get(opts, :seed_y, seed_x + 1)
    grid_w = Keyword.get(opts, :grid_w, @default_noise_grid_w)
    grid_h = Keyword.get(opts, :grid_h, @default_noise_grid_h)
    wrap? = Keyword.get(opts, :wrap, true)

    node = perlin_node!(opts)

    {:ok, grid2, {min_x, max_x}, {min_y, max_y}} =
      FastNoise2.gen_uniform_grid2d2(node, 0, 0, grid_w, grid_h, frequency, seed_x, seed_y)

    bytes_per_grid = grid_w * grid_h * 4

    noise_x =
      make_noise_sampler_from_grid(grid2, 0, world_w, world_h, grid_w, grid_h, min_x, max_x, wrap: wrap?)

    noise_y =
      make_noise_sampler_from_grid(grid2, bytes_per_grid, world_w, world_h, grid_w, grid_h, min_y, max_y, wrap: wrap?)

    {noise_x, noise_y}
  end

  def make_noise_sampler(node, world_w, world_h, grid_w, grid_h, frequency, seed, opts \\ []) do
    wrap? = Keyword.get(opts, :wrap, true)
    normalize? = Keyword.get(opts, :normalize, false)

    {:ok, grid, {min, max}} = FastNoise2.gen_uniform_grid2d(node, 0, 0, grid_w, grid_h, frequency, seed)
    make_noise_sampler_from_grid(grid, 0, world_w, world_h, grid_w, grid_h, min, max,
      wrap: wrap?,
      normalize: normalize?
    )
  end

  def make_noise_sampler_from_grid(grid, base_offset, world_w, world_h, grid_w, grid_h, min, max, opts \\ []) do
    wrap? = Keyword.get(opts, :wrap, true)
    normalize? = Keyword.get(opts, :normalize, false)
    denom = max(max - min, 1.0e-9)

    fn x, y ->
      sample_grid2d(grid, base_offset, world_w, world_h, grid_w, grid_h, min, denom, x, y, wrap?, normalize?)
    end
  end

  defp sample_grid2d(grid, base_offset, world_w, world_h, grid_w, grid_h, min, denom, x, y, wrap?, normalize?) do
    gx = x / world_w * (grid_w - 1)
    gy = y / world_h * (grid_h - 1)

    {ix0, ix1, tx} =
      if wrap? do
        ix0 = floor(gx)
        tx = gx - ix0 * 1.0
        ix0 = pos_rem(ix0, grid_w)
        ix1 = pos_rem(ix0 + 1, grid_w)
        {ix0, ix1, tx}
      else
        gx = gx |> max(0.0) |> min(grid_w - 1.001)
        ix0 = floor(gx)
        tx = gx - ix0 * 1.0
        ix1 = min(ix0 + 1, grid_w - 1)
        {ix0, ix1, tx}
      end

    {iy0, iy1, ty} =
      if wrap? do
        iy0 = floor(gy)
        ty = gy - iy0 * 1.0
        iy0 = pos_rem(iy0, grid_h)
        iy1 = pos_rem(iy0 + 1, grid_h)
        {iy0, iy1, ty}
      else
        gy = gy |> max(0.0) |> min(grid_h - 1.001)
        iy0 = floor(gy)
        ty = gy - iy0 * 1.0
        iy1 = min(iy0 + 1, grid_h - 1)
        {iy0, iy1, ty}
      end

    v00 = grid_at(grid, base_offset, grid_w, ix0, iy0)
    v10 = grid_at(grid, base_offset, grid_w, ix1, iy0)
    v01 = grid_at(grid, base_offset, grid_w, ix0, iy1)
    v11 = grid_at(grid, base_offset, grid_w, ix1, iy1)

    v0 = v00 * (1.0 - tx) + v10 * tx
    v1 = v01 * (1.0 - tx) + v11 * tx
    v = v0 * (1.0 - ty) + v1 * ty

    if normalize? do
      (v - min) / denom
    else
      v
    end
  end

  defp pos_rem(i, m) do
    r = rem(i, m)
    if r < 0, do: r + m, else: r
  end

  defp grid_at(grid, base_offset, grid_w, ix, iy) do
    offset = base_offset + (iy * grid_w + ix) * 4
    <<v::little-float-32>> = :binary.part(grid, offset, 4)
    v
  end

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
        interpolate(acc, initial_deviation, opts)
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

      case @jitter_dist do
        :perlin -> update_xy_perlin(points, effective_deviation, opts)
        _ -> Enum.map(points, &move_nearby_xy(&1, effective_deviation, opts))
      end
    end
  end

  defp update_xy_perlin(points, effective_deviation, opts) do
    noise_x =
      Keyword.get(opts, :noise_x) ||
        raise "missing :noise_x for @jitter_dist :perlin (pass noise_x: make_noise_sampler(...))"

    noise_y =
      Keyword.get(opts, :noise_y) ||
        raise "missing :noise_y for @jitter_dist :perlin (pass noise_y: make_noise_sampler(...))"

    layer = Keyword.get(opts, :noise_layer, 0)
    layer_shift = Keyword.get(opts, :noise_layer_shift, @default_noise_layer_shift)
    shift = layer * layer_shift

    Enum.map(points, fn {x, y, z} ->
      stdev = abs(z * effective_deviation)

      {
        x + noise_x.(x + shift, y + shift) * stdev,
        y + noise_y.(x + shift, y + shift) * stdev
      }
    end)
  end

  defp interpolate([first, second | rest], sd, opts) do
    {rev, _last} =
      Enum.reduce([second | rest], {[first], first}, fn p2, {acc, p1} ->
        mid = generate_midpoint(p1, p2, sd, opts)
        {[p2, mid | acc], p2}
      end)

    rev
  end

  defp interpolate(points, _sd, _opts), do: points

  defp generate_midpoint({x1, y1, z1}, {x2, y2, z2}, sd, opts) do
    x = (x1 + x2) / 2.0
    y = (y1 + y2) / 2.0
    z = (z1 + z2) / 2.0 * 0.45 * rand_between(0.1, 3.5)
    move_nearby({x, y, z}, sd, opts)
  end

  defp move_nearby({_, _, _} = pnt, sd, _opts) when sd == 0 or sd == 0.0, do: pnt

  defp move_nearby({x, y, z}, sd, opts) do
    {x, y} = jitter_xy(x, y, z, sd, opts)
    {x, y, z}
  end

  defp move_nearby_xy({x, y, _z}, sd, _opts) when sd == 0 or sd == 0.0, do: {x, y}

  defp move_nearby_xy({x, y, z}, sd, opts) do
    jitter_xy(x, y, z, sd, opts)
  end

  defp rand_between(min, max), do: min + :rand.uniform() * (max - min)

  defp rand_gaussian(mean, stdev) when stdev == 0 or stdev == 0.0, do: mean

  defp rand_gaussian(mean, stdev) do
    mean + Blendend.Rand.normal() * stdev
  end

  defp rand_uniform_sd(mean, stdev) when stdev == 0 or stdev == 0.0, do: mean

  defp rand_uniform_sd(mean, stdev) do
    u = 2.0 * :rand.uniform() - 1.0
    mean + u * (stdev * :math.sqrt(3.0))
  end

  defp rand_triangular_sd(mean, stdev) when stdev == 0 or stdev == 0.0, do: mean

  defp rand_triangular_sd(mean, stdev) do
    t = :rand.uniform() + :rand.uniform() - 1.0
    mean + t * (stdev * :math.sqrt(6.0))
  end

  defp jitter_xy(x, y, z, sd, opts) do
    stdev = abs(z * sd)

    case @jitter_dist do
      :gaussian -> {rand_gaussian(x, stdev), rand_gaussian(y, stdev)}
      :uniform -> {rand_uniform_sd(x, stdev), rand_uniform_sd(y, stdev)}
      :triangular -> {rand_triangular_sd(x, stdev), rand_triangular_sd(y, stdev)}
      :perlin ->
        noise_x = Keyword.get(opts, :noise_x)
        noise_y = Keyword.get(opts, :noise_y)

        if is_function(noise_x, 2) and is_function(noise_y, 2) do
          {x + noise_x.(x, y) * stdev, y + noise_y.(x, y) * stdev}
        else
          {rand_gaussian(x, stdev), rand_gaussian(y, stdev)}
        end
    end
  end
end

alias BlendendPlaygroundPhx.Demos.Watercolor2

width = 1500
height = 1500

draw width, height do
  clear(fill: rgb(0xFF, 0xFA, 0xCE))

  canvas = get_canvas()

  noise =
    if Watercolor2.jitter_dist() == :perlin do
      Watercolor2.perlin_samplers!(width, height, wrap: true)
    end

  Enum.each(-100..(height - 1)//250, fn ypos ->
    points =
      if noise do
        {noise_x, noise_y} = noise
        Watercolor2.init_points(width, ypos, noise_x: noise_x, noise_y: noise_y)
      else
        Watercolor2.init_points(width, ypos)
      end

    hue = :rand.uniform() * 360.0
    fill_color = hsv(hue, 1, 0.8)

    Enum.each(1..42, fn layer ->
      current =
        if noise do
          {noise_x, noise_y} = noise
          Watercolor2.update_xy(points, noise_x: noise_x, noise_y: noise_y, noise_layer: layer)
        else
          Watercolor2.update_xy(points)
        end

      Blendend.Canvas.Fill.polygon(canvas, current,
        fill: fill_color,
        alpha: 0.01,
        comp_op: :difference
      )
    end)
  end)
end
