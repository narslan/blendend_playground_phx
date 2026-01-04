# path flattening demo
alias Blendend.Path
alias Blendend.Text.{Face, Font, GlyphBuffer, GlyphRun}
alias BlendendPlaygroundPhx.Palette
use BlendendPlaygroundPhx.Calculation.Macros

width = 800
height = 800

draw width, height do
  palette =
    "random"
    |> Palette.palette_by_name()
    |> Map.get(:colors, [])
    |> Palette.from_hex_list_rgb()
    |> Enum.map(fn {r, g, b} -> rgb(r, g, b) end)

  bg = rgb(0x2A, 0x31, 0x18)
  clear(fill: bg)

  font = font("Alegreya", 120)

  letter = "iEx"

  gb =
    GlyphBuffer.new!()
    |> GlyphBuffer.set_utf8_text!(letter)
    |> Font.shape!(font)

  run = GlyphRun.new!(gb)

  mtx =
    matrix do
      translate(width * 0.1, height * 0.66)
      scale(3.8, 3.8)
    end

  p =
    Path.new!()
    |> Font.get_glyph_run_outlines!(font, run, mtx)

  # fill_path(p, fill: bg)
  #  shadow_path(p, 10.0, 1.0, 10.0, fill: rgb(0xFF,0xFF,0x68, 100))

  spacing = 15.0
  flat = Path.flatten!(p, 0.8)

  flat
  |> Path.segments()
  |> Path.sample(spacing)
  |> Enum.each(fn {{x, y}, {tx, ty}} ->
    # Perpendicular directions for outward strokes
    nx = ty
    ny = -tx

    col = Enum.random(palette)
    steps = :rand.uniform(10) + 10
    speed = rand_between(1.0, 2.0)
    angle0 = :rand.uniform() * :math.pi() * 2

    pts =
      Stream.iterate({x, y, angle0}, fn {px, py, a} ->
        ang = a + :rand.uniform() * 0.8
        {px + :math.cos(ang) * speed, py + :math.sin(ang) * speed, ang}
      end)
      |> Enum.take(steps)

    path_flare =
      Enum.reduce(pts, nil, fn
        {px, py, _}, nil -> Path.new!() |> Path.move_to!(px, py)
        {px, py, _}, acc -> Path.line_to!(acc, px, py)
      end)

    stroke_path(path_flare,
      stroke: col,
      stroke_width: rand_between(1.2, 1.6),
      stroke_cap: :round
    )

    # occasional blossom along the flare
    if :rand.uniform() < 0.6 do
      petals = 5
      petal_r0 = rand_between(1.0, 2.0)
      petal_r1 = petal_r0 * rand_between(2.6, 4.2)
      center_x = x + nx * rand_between(2.0, 6.0)
      center_y = y + ny * rand_between(2.0, 6.0)
      petals_color = Enum.random(palette)

      petal_path =
        Enum.reduce(0..(petals - 1), Path.new!(), fn k, acc ->
          a0 = k * 2 * :math.pi() / petals
          a1 = a0 + :math.pi() / petals
          p0x = center_x + petal_r0 * :math.cos(a0)
          p0y = center_y + petal_r0 * :math.sin(a0)
          p1x = center_x + petal_r1 * :math.cos(a1)
          p1y = center_y + petal_r1 * :math.sin(a1)

          acc
          |> Path.move_to!(center_x, center_y)
          |> Path.line_to!(p0x, p0y)
          |> Path.line_to!(p1x, p1y)
        end)

      stroke_path(petal_path, stroke: petals_color)
    end
  end)

  # Light noise layer on top
  noise_color = rgb(255, 255, 255, 8)

  Enum.each(1..500, fn _ ->
    px = :rand.uniform() * width
    py = :rand.uniform() * height
    r = rand_between(1.4, 2.4)
    circle(px, py, r, fill: noise_color)
  end)
end
