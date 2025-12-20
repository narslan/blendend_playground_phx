# Catmull–Rom exercise: compare alpha=0.0 (uniform, p5-style) vs alpha=0.5
# (centripetal, reduced corner overshoot) on the same points.

alias Blendend.Path
alias BlendendPlayground.Curves

w = 900
h = 520

points = [
  {80, 320},
  {160, 90},
  {260, 430},
  {360, 120},
  {480, 380},
  {600, 140},
  {720, 360},
  {820, 260}
]

bg = rgb(0xF7, 0xF4, 0xEE)
poly_col = rgb(0, 0, 0, 40)
uniform_col = rgb(230, 90, 60, 200)
centripetal_col = rgb(40, 120, 230, 200)
pt_col = rgb(0, 0, 0, 160)

draw w, h do
  clear(fill: bg)

  # Underlying polyline
  poly =
    Enum.reduce(points, nil, fn
      {x, y}, nil -> Path.new!() |> Path.move_to!(x, y)
      {x, y}, acc -> Path.line_to!(acc, x, y)
    end)

  stroke_path(poly, stroke: poly_col, stroke_width: 2.0, stroke_cap: :round)

  # Curves
  uniform = Path.new!() |> Curves.curve_vertices!(points, alpha: 0.0)
  centripetal = Path.new!() |> Curves.curve_vertices!(points, alpha: 0.5)

  stroke_path(uniform, stroke: uniform_col, stroke_width: 4.5, stroke_cap: :round)
  stroke_path(centripetal, stroke: centripetal_col, stroke_width: 3.0, stroke_cap: :round)

  Enum.each(points, fn {x, y} -> circle(x, y, 5.5, fill: pt_col) end)
end
