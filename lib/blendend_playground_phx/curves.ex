defmodule BlendendPlaygroundPhx.Curves do
  @moduledoc """
  Playground helpers for smooth Catmull–Rom curves (p5-style `curveVertex`).

  These are kept here for iteration; once they settle we can upstream them to
  `Blendend.Path`.
  """

  alias Blendend.Path

  @typedoc "A 2D point."
  @type point :: {number(), number()}

  @doc """
  Appends a Catmull–Rom spline through `points` to the given `path`.

  Options:

    * `:tension` – cardinal tension in `[0, 1]`; `0.0` matches Catmull–Rom (default)
    * `:closed?` – whether to wrap endpoints for a closed loop (default: `false`)
    * `:matrix`  – optional `Blendend.Matrix2D.t()` applied after the curve is built
    * `:alpha`   – Catmull–Rom parameterization (`0.0` uniform like p5, `0.5` centripetal;
      default `0.0`). Higher values reduce corner overshoot.

  Points are streamed with a cyclic/duplicated wrapper, avoiding `++` copies even
  for large inputs. Returns the mutated `path`.
  """
  @spec curve_vertices!(Path.t(), [point()], keyword()) :: Path.t()
  def curve_vertices!(path, points, opts \\ []) do
    case points do
      [] -> path
      [_] -> path
      _ -> do_curve_vertices(path, points, opts)
    end
  end

  defp do_curve_vertices(path, points, opts) do
    closed? = Keyword.get(opts, :closed?, false)
    tension = Keyword.get(opts, :tension, 0.0)
    matrix = Keyword.get(opts, :matrix)
    alpha = Keyword.get(opts, :alpha, 0.0)

    pts = normalize_points(points)
    len = length(pts)
    factor = (1.0 - tension) / 3.0

    stream =
      if closed? do
        pts
        |> Stream.cycle()
        |> Stream.drop(len - 1)
        |> Stream.take(len + 3)
      else
        first = hd(pts)
        last = List.last(pts)
        Stream.concat([[first], pts, [last]])
      end

    stream
    |> Stream.chunk_every(4, 1, :discard)
    |> Enum.reduce({path, true}, fn [{x0, y0}, {x1, y1}, {x2, y2}, {x3, y3}], {acc, first?} ->
      t0 = 0.0
      t1 = t0 + chord_len({x0, y0}, {x1, y1}, alpha)
      t2 = t1 + chord_len({x1, y1}, {x2, y2}, alpha)
      t3 = t2 + chord_len({x2, y2}, {x3, y3}, alpha)

      # Tangents (Catmull–Rom), scaled for optional tension.
      dx1 = (x2 - x0) / max(t2 - t0, 1.0e-9)
      dy1 = (y2 - y0) / max(t2 - t0, 1.0e-9)
      dx2 = (x3 - x1) / max(t3 - t1, 1.0e-9)
      dy2 = (y3 - y1) / max(t3 - t1, 1.0e-9)

      h = (t2 - t1) * factor
      c1x = x1 + dx1 * h
      c1y = y1 + dy1 * h
      c2x = x2 - dx2 * h
      c2y = y2 - dy2 * h

      acc = if first?, do: Path.move_to!(acc, x1, y1), else: acc
      {Path.cubic_to!(acc, c1x, c1y, c2x, c2y, x2, y2), false}
    end)
    |> elem(0)
    |> maybe_transform(matrix)
  end

  defp normalize_points(points) do
    Enum.map(points, fn
      {x, y} -> {x * 1.0, y * 1.0}
      other -> raise ArgumentError, "point must be a {x, y} tuple, got: #{inspect(other)}"
    end)
  end

  defp maybe_transform(path, nil), do: path
  defp maybe_transform(path, matrix), do: Path.transform!(path, matrix)

  defp chord_len({x0, y0}, {x1, y1}, alpha) do
    dx = x1 - x0
    dy = y1 - y0
    :math.sqrt(dx * dx + dy * dy) |> :math.pow(alpha)
  end
end
