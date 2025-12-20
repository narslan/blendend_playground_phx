# Drawing catmull-Rom spline. Curves.curve_vertices!/3 mirrors curveVertex of p5.js

alias Blendend.Path
alias BlendendPlaygroundPhx.Palette
alias BlendendPlaygroundPhx.Curves

draw 400, 400 do
  [bg | palette] =
    Palette.palette_by_name("artists.VanGogh")
    |> Map.get(:colors, [])
    |> Palette.from_hex_list_rgb()
    |> Enum.map(fn {r, g, b} -> rgb(r, g, b) end)

  clear(fill: bg)

  # The list includes
  # first control point
  # two anchor points
  # second control point
  points = [{32, 91}, {21, 17}, {68, 19}, {84, 91}]

  Path.new!()
  |> Curves.curve_vertices!(points, closed?: false)
  |> Path.translate!(100, 100)
  |> stroke_path(stroke: Enum.random(palette))

  translate(100, 100)

  circle_color = Enum.random(palette)

  Stream.each(points, fn {x, y} -> circle(x, y, 3, fill: circle_color) end)
  |> Stream.run()

  p0 = {110.0, 150.0}
  c1 = {25.0, 190.0}
  c2 = {210.0, 250.0}
  p3 = {210.0, 30.0}

  curve_color = Enum.random(palette)
  curve_color2 = Enum.random(palette)

  curve =
    Path.new!()
    |> Path.move_to!(elem(p0, 0), elem(p0, 1))
    |> Path.cubic_to!(
      elem(c1, 0),
      elem(c1, 1),
      elem(c2, 0),
      elem(c2, 1),
      elem(p3, 0),
      elem(p3, 1)
    )

  curve2 =
    Path.new!()
    |> Path.move_to!(elem(p0, 0), elem(p0, 1))
    |> Path.conic_to!(
      elem(c1, 0),
      elem(c1, 1),
      elem(c2, 0),
      elem(c2, 1),
      1.0
    )

  stroke_path(curve, stroke: curve_color, stroke_width: 3.5, stroke_cap: :round)
  fill_path(curve2, fill: curve_color2)
end
