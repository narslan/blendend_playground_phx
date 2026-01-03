# Catmull–Rom exercise: compare alpha=0.0 (uniform, p5-style) vs alpha=0.5
# (centripetal, reduced corner overshoot) on the same points.

alias Blendend.Path
alias BlendendPlaygroundPhx.Curves
alias BlendendPlaygroundPhx.Palette

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

palette = Palette.palette_by_name("exposito.exposito")

hexes =
  List.wrap(Map.get(palette, :background, [])) ++ Map.get(palette, :colors, [])

rgbs =
  hexes
  |> Palette.from_hex_list_rgb()
  |> Enum.map(fn {r, g, b} -> rgb(r, g, b) end)

[bg | palette] = rgbs
poly_col = Enum.at(palette, 0)
uniform_col = Enum.at(palette, 1)
centripetal_col = Enum.at(palette, 2)
pt_col = Enum.at(palette, 3)

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
