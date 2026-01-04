# ased on the data from https://commons.wikimedia.org/wiki/File:Black_cherry_tree_histogram.svg
alias BlendendPlaygroundPhx.Axis
alias BlendendPlaygroundPhx.Ticks
use Blendend.Draw

w = 980
h = 620

margin = %{left: 90, right: 40, top: 60, bottom: 90}
plot_x0 = margin.left
plot_x1 = w - margin.right
plot_y0 = margin.top
plot_y1 = h - margin.bottom

trees = [
  {8.3, 70, 10.3},
  {8.6, 65, 10.3},
  {8.8, 63, 10.2},
  {10.5, 72, 16.4},
  {10.7, 81, 18.8},
  {10.8, 83, 19.7},
  {11.0, 66, 15.6},
  {11.0, 75, 18.2},
  {11.1, 80, 22.6},
  {11.2, 75, 19.9},
  {11.3, 79, 24.2},
  {11.4, 76, 21.0},
  {11.4, 76, 21.4},
  {11.7, 69, 21.3},
  {12.0, 75, 19.1},
  {12.9, 74, 22.2},
  {12.9, 85, 33.8},
  {13.3, 86, 27.4},
  {13.7, 71, 25.7},
  {13.8, 64, 24.9},
  {14.0, 78, 34.5},
  {14.2, 80, 31.7},
  {14.5, 74, 36.3},
  {16.0, 72, 38.3},
  {16.3, 77, 42.6},
  {17.3, 81, 55.4},
  {17.5, 82, 55.7},
  {17.9, 80, 58.3},
  {18.0, 80, 51.5},
  {18.0, 80, 51.0},
  {20.6, 87, 77.0}
]

heights = Enum.map(trees, fn {_girth, height, _volume} -> height * 1.0 end)
min_height = Enum.min(heights)
max_height = Enum.max(heights)

bin_size = 5
bin_start = :math.floor(min_height / bin_size) * bin_size
bin_stop = :math.ceil(max_height / bin_size) * bin_size

edges =
  bin_start
  |> Stream.iterate(&(&1 + bin_size))
  |> Enum.take_while(&(&1 < bin_stop))

bins =
  Enum.map(edges, fn edge ->
    %{
      label: "#{trunc(edge)}-#{trunc(edge + bin_size)}",
      start: edge,
      stop: edge + bin_size,
      count: 0
    }
  end)

bins =
  Enum.reduce(heights, bins, fn height, acc ->
    idx = :math.floor((height - bin_start) / bin_size) |> trunc()
    idx = min(max(idx, 0), length(acc) - 1)

    List.update_at(acc, idx, fn bin ->
      %{bin | count: bin.count + 1}
    end)
  end)

max_count = bins |> Enum.map(& &1.count) |> Enum.max()

format_count = fn value ->
  case value do
    v when is_integer(v) -> :io_lib.format(~c"~B", [v])
    v when is_float(v) -> :io_lib.format(~c"~B", [round(v)])
    other -> to_string(other)
  end
end

draw w, h do
  clear(fill: rgb(171, 233, 232))

  title_font = font("AlegreyaSans", 28.0)
  axis_font = font("MapleMono", 12.0)
  label_font = font("AlegreyaSans", 18.0)

  text(title_font, w / 3, 40, "Black cherry trees — height histogram", fill: rgb(24, 24, 28))
  # text(label_font, 28, 64, "Heights in feet, 5-ft bins", fill: rgb(70, 70, 80))

  x_domain = Enum.map(bins, & &1.label)

  x_scale =
    Scale.Band.new(
      domain: x_domain,
      range: [plot_x0, plot_x1],
      padding_inner: 0.0,
      padding_outer: 0.0
    )

  y_scale = Scale.Linear.new(domain: [0, max_count], range: [plot_y1, plot_y0])

  grid_color = rgb(210, 210, 210)

  Ticks.ticks(y_scale, tick_count: 5, tick_format: format_count)
  |> Enum.each(fn %{position: y} ->
    line(plot_x0, y, plot_x1, y, stroke: grid_color, stroke_width: 1.0)
  end)

  bar_fill = rgb(118, 90, 166)
  bar_outline = rgb(40, 70, 110)
  bar_width = Scale.Band.bandwidth(x_scale)

  Enum.each(bins, fn bin ->
    x = Scale.map(x_scale, bin.label)
    y = Scale.map(y_scale, bin.count)
    h = plot_y1 - y
    rect(x, y, bar_width, h, fill: bar_fill)
    rect(x, y, bar_width, h, stroke: bar_outline, stroke_width: 1.0)
  end)

  gap = 8.0

  Axis.draw(x_scale, :bottom,
    at: plot_y1 + gap,
    font: axis_font,
    tick_size: 6.0,
    tick_padding: 8.0
  )

  Axis.draw(y_scale, :left,
    at: plot_x0 - gap,
    font: axis_font,
    tick_count: 8,
    tick_format: format_count,
    tick_size: 6.0,
    tick_padding: 6.0
  )

  text(label_font, w / 2, plot_y1 + 52, "Height (ft)", fill: rgb(40, 40, 48))

  transform =
    matrix do
      translate(0, h / 2)
      rotate(-:math.pi() / 2)
    end

  with_transform transform do
    text(label_font, plot_x0 - 60, plot_y0 - 18, "Count", fill: rgb(40, 40, 48))
  end
end
