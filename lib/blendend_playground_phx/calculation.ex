defmodule BlendendPlaygroundPhx.Calculation do
  @moduledoc """
  Utility helpers inspired by p5.js math functions, exposed as both functions and macros
  so they can be used inline within drawing pipelines.
  """

  @doc """
  Maps a value from one range to another.

  Raises `ArgumentError` when the input range is zero-length.
  """
  @spec map(number(), number(), number(), number(), number()) :: float()
  def map(value, in_min, in_max, out_min, out_max) do
    in_span = in_max - in_min
    out_span = out_max - out_min

    if in_span == 0 do
      raise ArgumentError, "cannot map with zero input range"
    end

    out_min + (value - in_min) / in_span * out_span
  end

  @doc """
  Normalizes a value within a range to 0..1.
  """
  @spec norm(number(), number(), number()) :: float()
  def norm(value, start, stop) do
    map(value, start, stop, 0.0, 1.0)
  end

  @doc """
  Linearly interpolates between two numbers.
  """
  @spec lerp(number(), number(), number()) :: float()
  def lerp(start, stop, amt) do
    start + (stop - start) * amt
  end

  @doc """
  Squares a number.
  """
  @spec sq(number()) :: number()
  def sq(value), do: value * value

  @doc """
  Square root helper (delegates to :math.sqrt).
  """
  @spec sqrt(number()) :: float()
  def sqrt(value), do: :math.sqrt(value)

  @doc """
  Distance between two points.
  """
  @spec dist({number(), number()}, {number(), number()}) :: float()
  def dist(p1, p2) do
    x0 = elem(p1, 0)
    y0 = elem(p1, 1)
    x1 = elem(p2, 0)
    y1 = elem(p2, 1)
    sqrt(sq(y1 - y0) + sq(x1 - x0))
  end

  @doc """
  Generates a random angle in radians between -π and +π.
  """
  @spec rand_radian() :: float()
  def rand_radian do
    (:rand.uniform() * 2 - 1) * :math.pi()
  end

  @doc """
  Picks a random float between `min` and `max` (inclusive of `min`, exclusive of `max`).

  Swaps the arguments if they are provided in reverse order.
  """
  @spec rand_between(number(), number()) :: float()
  def rand_between(min, max) do
    {low, high} = if min <= max, do: {min, max}, else: {max, min}

    case high - low do
      0 -> low * 1.0
      span -> low + :rand.uniform() * span
    end
  end

  @doc """
  Picks a random integer between `min` and `max` (inclusive of both ends).

  Swaps the arguments if they are provided in reverse order.

  ## Examples

      iex> v = BlendendPlaygroundPhx.Calculation.rand_between_int(3, 5)
      iex> is_integer(v) and v in 3..5
      true

      iex> BlendendPlaygroundPhx.Calculation.rand_between_int(7, 7)
      7
  """
  @spec rand_between_int(integer(), integer()) :: integer()
  def rand_between_int(min, max) when is_integer(min) and is_integer(max) do
    {low, high} = if min <= max, do: {min, max}, else: {max, min}

    case high - low do
      0 ->
        low

      span ->
        low + :rand.uniform(span + 1) - 1
    end
  end

  @doc """
  Generates smooth 2D value noise in the `0.0..1.0` range.

  This is a lightweight alternative to Perlin noise: it hashes the surrounding
  integer lattice points and interpolates between them with a smoothstep curve.

  It's fast enough for per-pixel/per-segment rendering where a pure Elixir
  Perlin implementation would be too slow.

  ## Examples

      iex> v = BlendendPlaygroundPhx.Calculation.noise2(12.3, 45.6)
      iex> is_float(v) and v >= 0.0 and v < 1.0
      true

      iex> BlendendPlaygroundPhx.Calculation.noise2(12.3, 45.6) == BlendendPlaygroundPhx.Calculation.noise2(12.3, 45.6)
      true

      iex> v = BlendendPlaygroundPhx.Calculation.noise2(-0.2, -3.7)
      iex> v >= 0.0 and v < 1.0
      true
  """
  @spec noise2(number(), number()) :: float()
  def noise2(x, y), do: noise2(x, y, 0)

  @spec noise2(number(), number(), term()) :: float()
  def noise2(x, y, seed) do
    x = x * 1.0
    y = y * 1.0
    x0 = :math.floor(x) |> trunc()
    y0 = :math.floor(y) |> trunc()
    x1 = x0 + 1
    y1 = y0 + 1

    fx = x - x0
    fy = y - y0
    # interpolation weights
    sx = fade(fx)
    sy = fade(fy)

    # hash corner values of the current grid cell
    n00 = hash01({:noise2, seed, x0, y0})
    n10 = hash01({:noise2, seed, x1, y0})
    n01 = hash01({:noise2, seed, x0, y1})
    n11 = hash01({:noise2, seed, x1, y1})

    ix0 = lerp(n00, n10, sx)
    ix1 = lerp(n01, n11, sx)
    lerp(ix0, ix1, sy)
  end

  # fade/1 is the "smoothstep" curve used in classic Perlin interpolation.
  defp fade(t), do: t * t * t * (t * (t * 6.0 - 15.0) + 10.0)

  # :erlang.phash2({seed, x, y}, n) is a pure, 
  # deterministic mapping from coordinates -> pseudo-random value.
  defp hash01(term), do: :erlang.phash2(term, 1_000_000) / 1_000_000

  @doc """
  Same as `noise2/2` (or `/3`), but returns signed noise in the `-1.0..1.0` range.

  This is useful when porting algorithms that expect classic Perlin/simplex-style
  signed noise and then normalize it with `(n + 1) / 2`.
  """
  @spec noise2_signed(number(), number()) :: float()
  def noise2_signed(x, y), do: noise2_signed(x, y, 0)

  @spec noise2_signed(number(), number(), term()) :: float()
  def noise2_signed(x, y, seed), do: noise2(x, y, seed) * 2.0 - 1.0
end
