# Bezier exercise: visualize a single cubic Bezier (endpoints + handles),
# and sample points along the curve after flattening.

alias Blendend.Path

w = 900
h = 600

p0 = {120.0, 420.0}
c1 = {240.0, 120.0}
c2 = {610.0, 520.0}
p3 = {780.0, 180.0}

bg = rgb(0xF6, 0xF2, 0xEA)
curve_col = rgb(30, 40, 60, 220)
handle_col = rgb(30, 40, 60, 70)
sample_col = rgb(20, 20, 20, 70)

pt_end = rgb(220, 80, 70)
pt_ctrl = rgb(60, 130, 230)

draw w, h do
  clear(fill: bg)

  # Handle lines
  line(elem(p0, 0), elem(p0, 1), elem(c1, 0), elem(c1, 1), stroke: handle_col, stroke_width: 2.0)
  line(elem(p3, 0), elem(p3, 1), elem(c2, 0), elem(c2, 1), stroke: handle_col, stroke_width: 2.0)

  # Curve
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

  stroke_path(curve, stroke: curve_col, stroke_width: 3.5, stroke_cap: :round)

  # Tangent hints at endpoints (derivative direction).
  {tx0, ty0} = {elem(c1, 0) - elem(p0, 0), elem(c1, 1) - elem(p0, 1)}
  {tx1, ty1} = {elem(p3, 0) - elem(c2, 0), elem(p3, 1) - elem(c2, 1)}
  scale0 = 0.35
  scale1 = 0.35

  line(elem(p0, 0), elem(p0, 1), elem(p0, 0) + tx0 * scale0, elem(p0, 1) + ty0 * scale0,
    stroke: rgb(0, 0, 0, 70),
    stroke_width: 2.0,
    stroke_cap: :round
  )

  line(elem(p3, 0), elem(p3, 1), elem(p3, 0) + tx1 * scale1, elem(p3, 1) + ty1 * scale1,
    stroke: rgb(0, 0, 0, 70),
    stroke_width: 2.0,
    stroke_cap: :round
  )

  # Sample points along the curve (equal arc-length-ish along the flattened polyline).
  curve
  |> Path.flatten!(0.6)
  |> Path.segments()
  |> Path.sample(18.0)
  |> Enum.each(fn {{x, y}, _t} ->
    circle(x, y, 3.0, fill: sample_col)
  end)

  # Markers
  Enum.each([p0, p3], fn {x, y} -> circle(x, y, 7.0, fill: pt_end) end)
  Enum.each([c1, c2], fn {x, y} -> circle(x, y, 6.0, fill: pt_ctrl) end)
end
