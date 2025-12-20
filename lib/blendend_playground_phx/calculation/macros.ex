defmodule BlendendPlaygroundPhx.Calculation.Macros do
  @moduledoc """
  Macro wrappers around `BlendendPlaygroundPhx.Calculation` helpers for inline math.
  """

  alias BlendendPlaygroundPhx.Calculation

  defmacro __using__(_opts) do
    quote do
      require unquote(__MODULE__)
      import unquote(__MODULE__)
    end
  end

  defmacro map(value, in_min, in_max, out_min, out_max) do
    quote bind_quoted: [
            value: value,
            in_min: in_min,
            in_max: in_max,
            out_min: out_min,
            out_max: out_max
          ] do
      Calculation.map(value, in_min, in_max, out_min, out_max)
    end
  end

  defmacro norm(value, start, stop) do
    quote bind_quoted: [value: value, start: start, stop: stop] do
      Calculation.norm(value, start, stop)
    end
  end

  defmacro lerp(start, stop, amt) do
    quote bind_quoted: [start: start, stop: stop, amt: amt] do
      Calculation.lerp(start, stop, amt)
    end
  end

  defmacro sq(value) do
    quote bind_quoted: [value: value] do
      Calculation.sq(value)
    end
  end

  defmacro sqrt(value) do
    quote bind_quoted: [value: value] do
      Calculation.sqrt(value)
    end
  end

  defmacro rand_radian do
    quote do
      Calculation.rand_radian()
    end
  end

  defmacro rand_between(min, max) do
    quote bind_quoted: [min: min, max: max] do
      Calculation.rand_between(min, max)
    end
  end

  defmacro dist(p1, p2) do
    quote bind_quoted: [p1: p1, p2: p2] do
      Calculation.dist(p1, p2)
    end
  end

  defmacro noise2(x, y) do
    quote bind_quoted: [x: x, y: y] do
      Calculation.noise2(x, y)
    end
  end

  defmacro noise2(x, y, seed) do
    quote bind_quoted: [x: x, y: y, seed: seed] do
      Calculation.noise2(x, y, seed)
    end
  end

  defmacro noise2_signed(x, y) do
    quote bind_quoted: [x: x, y: y] do
      Calculation.noise2_signed(x, y)
    end
  end

  defmacro noise2_signed(x, y, seed) do
    quote bind_quoted: [x: x, y: y, seed: seed] do
      Calculation.noise2_signed(x, y, seed)
    end
  end

  # trig helpers (radian input)
  defmacro sin(angle) do
    quote do
      :math.sin(unquote(angle))
    end
  end

  defmacro cos(angle) do
    quote do
      :math.cos(unquote(angle))
    end
  end

  defmacro tan(angle) do
    quote do
      :math.tan(unquote(angle))
    end
  end

  defmacro atan2(y, x) do
    quote do
      :math.atan2(unquote(y), unquote(x))
    end
  end
end
