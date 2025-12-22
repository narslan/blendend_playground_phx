defmodule BlendendPlaygroundPhx.Ticks do
  @moduledoc """
  Tick calculation and formatting for axes.

  This module returns ticks as `%{value, position, label}` maps, where `position`
  is already mapped into the scale range (plus any optional offsets).
  """

  @type tick :: %{value: term(), position: number(), label: String.t()}

  @doc """
  Returns ticks for a scale as `%{value, position, label}` maps.

  Options:

    * `:tick_values` - explicit list of tick values (default: inferred from domain).
    * `:tick_count` - desired tick count for numeric domains (default: `5`).
    * `:tick_format` - `(value -> iodata)` formatter for tick labels (default: auto).
    * `:band_align` - `:start | :center | :end` for band scales (default: `:center`).
    * `:tick_offset` - numeric offset added to mapped positions (default: `0.0`).
  """
  @spec ticks(term(), keyword()) :: [tick()]
  def ticks(scale, opts \\ []) do
    values = tick_values(scale, opts)
    formatter = tick_formatter(opts)

    values
    |> Enum.reduce([], fn value, acc ->
      case tick_position(scale, value, opts) do
        nil ->
          acc

        pos when is_number(pos) ->
          label = formatter.(normalize_zero(value)) |> IO.iodata_to_binary()
          [%{value: value, position: pos * 1.0, label: label} | acc]

        other ->
          raise ArgumentError, "axis tick position must be numeric, got: #{inspect(other)}"
      end
    end)
    |> Enum.reverse()
  end

  defp tick_values(scale, opts) do
    case Keyword.fetch(opts, :tick_values) do
      {:ok, values} ->
        values

      :error ->
        domain = Scale.domain(scale)

        cond do
          numeric_pair?(domain) ->
            ticks_linear(domain, tick_count(opts))

          is_list(domain) ->
            domain

          true ->
            []
        end
    end
  end

  defp tick_position(%Scale.Band{} = scale, value, opts) do
    case Scale.map(scale, value) do
      nil ->
        nil

      pos ->
        align = Keyword.get(opts, :band_align, :center)
        offset = Keyword.get(opts, :tick_offset, 0.0) * 1.0
        bandwidth = Scale.Band.bandwidth(scale)

        aligned =
          case align do
            :start -> pos
            :center -> pos + bandwidth / 2.0
            :end -> pos + bandwidth
            other -> raise ArgumentError, "invalid :band_align value: #{inspect(other)}"
          end

        aligned + offset
    end
  end

  defp tick_position(scale, value, opts) do
    pos = Scale.map(scale, value)
    offset = Keyword.get(opts, :tick_offset, 0.0) * 1.0

    if is_number(pos) do
      pos + offset
    else
      raise ArgumentError, "axis tick position must be numeric, got: #{inspect(pos)}"
    end
  end

  defp tick_formatter(opts) do
    case Keyword.get(opts, :tick_format) do
      fun when is_function(fun, 1) ->
        fun

      nil ->
        &default_format/1

      other ->
        raise ArgumentError, ":tick_format must be a 1-arity function, got: #{inspect(other)}"
    end
  end

  defp default_format(value) when is_integer(value), do: Integer.to_string(value)

  defp default_format(value) when is_float(value) do
    value = normalize_zero(value)

    if near_integer?(value) do
      value |> round() |> Integer.to_string()
    else
      :io_lib.format(~c"~.4f", [value])
      |> IO.iodata_to_binary()
      |> trim_trailing_zeros()
    end
  end

  defp default_format(value), do: to_string(value)

  defp ticks_linear([d0, d1], count) do
    reverse? = d1 < d0
    start = if reverse?, do: d1, else: d0
    stop = if reverse?, do: d0, else: d1

    if start == stop do
      [start * 1.0]
    else
      step = tick_step(start, stop, count)

      if step == 0.0 do
        [start * 1.0, stop * 1.0]
      else
        i0 = :math.ceil(start / step) |> trunc()
        i1 = :math.floor(stop / step) |> trunc()

        ticks =
          if i1 < i0 do
            []
          else
            Enum.map(i0..i1, fn i -> normalize_zero(i * step) end)
          end

        if reverse?, do: Enum.reverse(ticks), else: ticks
      end
    end
  end

  defp tick_step(start, stop, count) do
    span = stop - start
    target = span / max(count, 1)
    power = :math.floor(:math.log10(target))
    error = target / :math.pow(10.0, power)

    factor =
      cond do
        error >= :math.sqrt(50.0) -> 10.0
        error >= :math.sqrt(10.0) -> 5.0
        error >= :math.sqrt(2.0) -> 2.0
        true -> 1.0
      end

    factor * :math.pow(10.0, power)
  end

  defp tick_count(opts) do
    case Keyword.get(opts, :tick_count, 5) do
      count when is_integer(count) and count > 0 -> count
      count when is_float(count) and count > 0 -> trunc(Float.round(count))
      other -> raise ArgumentError, ":tick_count must be a number > 0, got: #{inspect(other)}"
    end
  end

  defp numeric_pair?([a, b]) when is_number(a) and is_number(b), do: true
  defp numeric_pair?({a, b}) when is_number(a) and is_number(b), do: true
  defp numeric_pair?(_), do: false

  defp normalize_zero(value) when is_float(value) do
    if abs(value) < 1.0e-9, do: 0.0, else: value
  end

  defp normalize_zero(value), do: value

  defp near_integer?(value) do
    abs(value - Float.round(value)) < 1.0e-9
  end

  defp trim_trailing_zeros(value) do
    trimmed = String.trim_trailing(value, "0")
    if String.ends_with?(trimmed, "."), do: String.trim_trailing(trimmed, "."), else: trimmed
  end
end
