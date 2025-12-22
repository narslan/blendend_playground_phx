defmodule BlendendPlaygroundPhx.Axis do
  @moduledoc """
  Draws simple axes using `Scale` and `Blendend.Draw`.

  This module focuses on visual experimentation. It supports numeric scales
  (linear) and band scales (categorical) by mapping ticks to the scale range.

  ## Example

      alias BlendendPlaygroundPhx.Axis
      use Blendend.Draw

      w = 900
      h = 600
      margin = %{left: 80, right: 40, top: 50, bottom: 70}
      plot_x0 = margin.left
      plot_x1 = w - margin.right
      plot_y0 = margin.top
      plot_y1 = h - margin.bottom

      draw w, h do
        clear(fill: rgb(248, 248, 248))
        title_font = load_font("priv/fonts/AlegreyaSans-Regular.otf", 26.0)
        axis_font = load_font("priv/fonts/MapleMono-Regular.otf", 12.0)

        text(title_font, 24, 36, "Axis playground", fill: rgb(30, 30, 40))

        x_scale = Scale.Linear.new(domain: [0, 10], range: [plot_x0, plot_x1])
        y_scale = Scale.Linear.new(domain: [-1, 1], range: [plot_y1, plot_y0])

        Axis.draw(x_scale, :bottom, at: plot_y1, font: axis_font, tick_count: 8)
        Axis.draw(y_scale, :left, at: plot_x0, font: axis_font, tick_count: 8)

        points =
          for i <- 0..200 do
            x = 10.0 * i / 200
            y = :math.sin(x)
            {Scale.map(x_scale, x), Scale.map(y_scale, y)}
          end

        polyline(points, stroke: rgb(6, 53, 115, 200), stroke_width: 3.0)
      end
  """

  alias Blendend.Draw

  @type orientation :: :bottom | :top | :left | :right
  @type tick :: %{value: term(), position: number(), label: String.t()}

  @doc """
  Returns ticks for a scale as `%{value, position, label}` maps.

  Options:

    * `:tick_values` - explicit list of tick values (default: inferred from domain).
    * `:tick_count` - desired tick count for numeric domains (default: `5`).
    * `:tick_format` - `(value -> iodata)` formatter for tick labels (default: auto).
      This is useful for custom precision or units, for example:

          fn value -> :io_lib.format(~c"~.2f s", [value]) end
          fn value -> :io_lib.format(~c"~B", [round(value)]) end

      The return value is converted with `IO.iodata_to_binary/1`.
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

  @doc """
  Draws an axis at a given position and returns the ticks that were rendered.

  Required options:

    * `:at` - baseline coordinate (y for horizontal axes, x for vertical axes).

  Options:

    * `:font` - font for tick labels (required when `:show_tick_labels` is `true`).
    * `:tick_size` - tick length (default: `6.0`).
    * `:tick_padding` - spacing between tick and label (default: `4.0`).
    * `:tick_label_align` - `:start | :center | :end` (default depends on orientation).
    * `:tick_label_offset` - `{dx, dy}` adjustment for labels (default: `{0.0, 0.0}`).
    * `:stroke` - axis line color (default: dark gray).
    * `:tick_stroke` - tick line color (default: `:stroke`).
    * `:label_fill` - tick label color (default: `:stroke`).
    * `:stroke_width` - axis line width (default: `1.0`).
    * `:tick_width` - tick line width (default: `:stroke_width`).
    * `:show_domain` - draw axis line (default: `true`).
    * `:show_ticks` - draw tick marks (default: `true`).
    * `:show_tick_labels` - draw tick labels (default: `true`).

  Tick generation options are the same as in `ticks/2`.
  """
  @spec draw(term(), orientation(), keyword()) :: [tick()]
  def draw(scale, orientation, opts \\ [])

  def draw(scale, orientation, opts) when orientation in [:bottom, :top, :left, :right] do
    {r0, r1} = numeric_range!(scale)
    at = Keyword.get(opts, :at, 0.0) * 1.0
    tick_size = Keyword.get(opts, :tick_size, 6.0) * 1.0
    tick_padding = Keyword.get(opts, :tick_padding, 4.0) * 1.0
    show_domain? = Keyword.get(opts, :show_domain, true)
    show_ticks? = Keyword.get(opts, :show_ticks, true)
    show_labels? = Keyword.get(opts, :show_tick_labels, true)
    axis_stroke = Keyword.get(opts, :stroke, Draw.rgb(30, 30, 30))
    tick_stroke = Keyword.get(opts, :tick_stroke, axis_stroke)
    label_fill = Keyword.get(opts, :label_fill, axis_stroke)
    axis_width = Keyword.get(opts, :stroke_width, 1.0) * 1.0
    tick_width = Keyword.get(opts, :tick_width, axis_width) * 1.0
    label_align = Keyword.get(opts, :tick_label_align, default_label_align(orientation))
    {label_dx, label_dy} = Keyword.get(opts, :tick_label_offset, {0.0, 0.0})
    font = fetch_font(opts, show_labels?)

    ticks = ticks(scale, opts)

    tick_draw_opts = %{
      ticks: ticks,
      axis_pos: at,
      tick_size: tick_size,
      tick_padding: tick_padding,
      show_ticks?: show_ticks?,
      show_labels?: show_labels?,
      font: font,
      tick_stroke: tick_stroke,
      tick_width: tick_width,
      label_fill: label_fill,
      label_align: label_align,
      label_dx: label_dx,
      label_dy: label_dy
    }

    case orientation do
      :bottom ->
        if show_domain? do
          Draw.line(r0, at, r1, at, stroke: axis_stroke, stroke_width: axis_width)
        end

        tick_draw_opts
        |> Map.put(:axis, :horizontal)
        |> Map.put(:dir, 1.0)
        |> draw_ticks()

      :top ->
        if show_domain? do
          Draw.line(r0, at, r1, at, stroke: axis_stroke, stroke_width: axis_width)
        end

        tick_draw_opts
        |> Map.put(:axis, :horizontal)
        |> Map.put(:dir, -1.0)
        |> draw_ticks()

      :left ->
        if show_domain? do
          Draw.line(at, r0, at, r1, stroke: axis_stroke, stroke_width: axis_width)
        end

        tick_draw_opts
        |> Map.put(:axis, :vertical)
        |> Map.put(:dir, -1.0)
        |> draw_ticks()

      :right ->
        if show_domain? do
          Draw.line(at, r0, at, r1, stroke: axis_stroke, stroke_width: axis_width)
        end

        tick_draw_opts
        |> Map.put(:axis, :vertical)
        |> Map.put(:dir, 1.0)
        |> draw_ticks()
    end

    ticks
  end

  def draw(_scale, orientation, _opts) do
    raise ArgumentError,
          "axis orientation must be :bottom | :top | :left | :right, got: #{inspect(orientation)}"
  end

  defp draw_ticks(%{
         axis: axis,
         ticks: ticks,
         axis_pos: axis_pos,
         tick_size: tick_size,
         tick_padding: tick_padding,
         dir: dir,
         show_ticks?: show_ticks?,
         show_labels?: show_labels?,
         font: font,
         tick_stroke: tick_stroke,
         tick_width: tick_width,
         label_fill: label_fill,
         label_align: label_align,
         label_dx: label_dx,
         label_dy: label_dy
       })
       when axis in [:horizontal, :vertical] do
    Enum.each(ticks, fn %{position: pos, label: label} ->
      case axis do
        :horizontal ->
          x = pos
          y = axis_pos

          if show_ticks? do
            Draw.line(x, y, x, y + dir * tick_size, stroke: tick_stroke, stroke_width: tick_width)
          end

          if show_labels? do
            label_x = align_label_x(font, label, x, label_align) + label_dx
            label_y = y + dir * (tick_size + tick_padding) + label_dy
            Draw.text(font, label_x, label_y, label, fill: label_fill)
          end

        :vertical ->
          x = axis_pos
          y = pos

          if show_ticks? do
            Draw.line(x, y, x + dir * tick_size, y, stroke: tick_stroke, stroke_width: tick_width)
          end

          if show_labels? do
            base_x = x + dir * (tick_size + tick_padding)
            label_x = align_label_x(font, label, base_x, label_align) + label_dx
            label_y = y + label_dy
            Draw.text(font, label_x, label_y, label, fill: label_fill)
          end
      end
    end)
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

  defp numeric_range!(scale) do
    case Scale.range(scale) do
      [a, b] when is_number(a) and is_number(b) -> {a * 1.0, b * 1.0}
      {a, b} when is_number(a) and is_number(b) -> {a * 1.0, b * 1.0}
      other -> raise ArgumentError, "axis scale range must be numeric, got: #{inspect(other)}"
    end
  end

  defp numeric_pair?([a, b]) when is_number(a) and is_number(b), do: true
  defp numeric_pair?({a, b}) when is_number(a) and is_number(b), do: true
  defp numeric_pair?(_), do: false

  defp default_label_align(:bottom), do: :center
  defp default_label_align(:top), do: :center
  defp default_label_align(:left), do: :end
  defp default_label_align(:right), do: :start

  defp fetch_font(opts, true) do
    case Keyword.get(opts, :font) do
      nil -> raise ArgumentError, ":font is required when :show_tick_labels is true"
      font -> font
    end
  end

  defp fetch_font(_opts, false), do: nil

  defp align_label_x(_font, _label, x, :start), do: x
  defp align_label_x(_font, _label, x, :left), do: x

  defp align_label_x(nil, _label, x, _align), do: x

  defp align_label_x(font, label, x, align) do
    case safe_text_advance(font, label) do
      {:ok, w} ->
        case align do
          :center -> x - w / 2.0
          :end -> x - w
          :right -> x - w
          _ -> x
        end

      {:error, _reason} ->
        x
    end
  end

  defp safe_text_advance(font, label) do
    with {:ok, gb} <- Blendend.Text.GlyphBuffer.new(),
         :ok <- Blendend.Text.GlyphBuffer.set_utf8_text(gb, label),
         {:ok, %{"advance_x" => w}} <- Blendend.Text.Font.get_text_metrics(font, gb),
         true <- is_number(w) do
      {:ok, w}
    else
      {:error, reason} -> {:error, reason}
      false -> {:error, :invalid_advance}
      other -> {:error, other}
    end
  end

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
