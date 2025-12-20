# Bezier exercise: see what `smooth_cubic_to` does by overlaying it with an
# explicit cubic whose first control point is the reflection of the previous
# segment's second control point.

alias Blendend.Path

w = 900
h = 520

p0 = {120.0, 360.0}
c1 = {220.0, 80.0}
c2 = {360.0, 520.0}
p1 = {460.0, 300.0}

c3 = {640.0, 60.0}
p2 = {780.0, 360.0}

reflected = {2.0 * elem(p1, 0) - elem(c2, 0), 2.0 * elem(p1, 1) - elem(c2, 1)}

bg = rgb(0xF8, 0xF6, 0xF1)
handle_col = rgb(0, 0, 0, 60)
path_a_col = rgb(40, 70, 200, 210)
path_b_col = rgb(230, 90, 60, 140)

pt_end = rgb(220, 80, 70)
pt_ctrl = rgb(60, 130, 230)
pt_ref = rgb(40, 170, 110)

draw w, h do
  clear(fill: bg)

  # Path A: uses smooth_cubic_to
  a =
    Path.new!()
    |> Path.move_to!(elem(p0, 0), elem(p0, 1))
    |> Path.cubic_to!(
      elem(c1, 0),
      elem(c1, 1),
      elem(c2, 0),
      elem(c2, 1),
      elem(p1, 0),
      elem(p1, 1)
    )
    |> Path.smooth_cubic_to!(elem(c3, 0), elem(c3, 1), elem(p2, 0), elem(p2, 1))

  # Path B: explicit reflected handle (should match Path A)
  b =
    Path.new!()
    |> Path.move_to!(elem(p0, 0), elem(p0, 1))
    |> Path.cubic_to!(
      elem(c1, 0),
      elem(c1, 1),
      elem(c2, 0),
      elem(c2, 1),
      elem(p1, 0),
      elem(p1, 1)
    )
    |> Path.cubic_to!(
      elem(reflected, 0),
      elem(reflected, 1),
      elem(c3, 0),
      elem(c3, 1),
      elem(p2, 0),
      elem(p2, 1)
    )

  stroke_path(a, stroke: path_a_col, stroke_width: 5.0, stroke_cap: :round)
  stroke_path(b, stroke: path_b_col, stroke_width: 2.5, stroke_cap: :round)

  # Helper lines (handles)
  line(elem(p0, 0), elem(p0, 1), elem(c1, 0), elem(c1, 1), stroke: handle_col, stroke_width: 2.0)
  line(elem(p1, 0), elem(p1, 1), elem(c2, 0), elem(c2, 1), stroke: handle_col, stroke_width: 2.0)

  line(elem(p1, 0), elem(p1, 1), elem(reflected, 0), elem(reflected, 1),
    stroke: handle_col,
    stroke_width: 2.0
  )

  line(elem(p2, 0), elem(p2, 1), elem(c3, 0), elem(c3, 1), stroke: handle_col, stroke_width: 2.0)

  # Points
  Enum.each([p0, p1, p2], fn {x, y} -> circle(x, y, 7.0, fill: pt_end) end)
  Enum.each([c1, c2, c3], fn {x, y} -> circle(x, y, 6.0, fill: pt_ctrl) end)
  circle(elem(reflected, 0), elem(reflected, 1), 6.0, fill: pt_ref)
end
