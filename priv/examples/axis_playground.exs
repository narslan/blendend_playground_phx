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
  clear(fill: rgb(231, 232, 216))

  title_font = font("AlegreyaSans", 26.0)
  axis_font = font("MapleMono", 12.0)

  text(title_font, 24, 36, "Axis playground", fill: rgb(30, 30, 40))

  x_scale = Scale.Linear.new(domain: [0, 10], range: [plot_x0, plot_x1])
  y_scale = Scale.Linear.new(domain: [-1, 1], range: [plot_y1, plot_y0])
  x_axis_y = Scale.map(y_scale, 0.0)

  Axis.draw(x_scale, :bottom,
    at: plot_y1,
    font: axis_font,
    tick_count: 8,
    tick_size: 8.0,
    tick_padding: 18.0
  )

  Axis.draw(y_scale, :left,
    at: plot_x0,
    font: axis_font,
    tick_count: 8,
    tick_size: 8.0,
    tick_padding: 6.0
  )

  steps = 120

  points =
    for i <- 0..steps do
      x = 10.0 * i / steps
      y = :math.sin(x)
      {Scale.map(x_scale, x), Scale.map(y_scale, y)}
    end

  polyline(points, stroke: rgb(6, 53, 115, 200), stroke_width: 3.0)
end
