# Port of https://openprocessing.org/sketch/1630344 to blendend.
# Staggered rows of clipped circles filled with layered petals.
defmodule BlendendPlaygroundPhx.Demos.FloralWave do
  @palettes [
    "202c39-283845-b8b08d-f2d492-f29559",
    "1f2041-4b3f72-ffc857-119da4-19647e",
    "2f4858-33658a-86bbd8-f6ae2d-f26419",
    "ffac81-ff928b-fec3a6-efe9ae-cdeac0",
    "f79256-fbd1a2-7dcfb6-00b2ca-1d4e89",
    "e27396-ea9ab2-efcfe3-eaf2d7-b3dee2",
    "966b9d-c98686-f2b880-fff4ec-e7cfbc",
    "50514f-f25f5c-ffe066-247ba0-70c1b3",
    "177e89-084c61-db3a34-ffc857-323031",
    "390099-9e0059-ff0054-ff5400-ffbd00",
    "0d3b66-faf0ca-f4d35e-ee964b-f95738",
    "780000-c1121f-fdf0d5-003049-669bbc",
    "eae4e9-fff1e6-fde2e4-fad2e1-e2ece9-bee1e6-f0efeb-dfe7fd-cddafd",
    "f94144-f3722c-f8961e-f9c74f-90be6d-43aa8b-577590",
    "555b6e-89b0ae-bee3db-faf9f9-ffd6ba",
    "9b5de5-f15bb5-fee440-00bbf9-00f5d4",
    "ef476f-ffd166-06d6a0-118ab2-073b4c",
    "006466-065a60-0b525b-144552-1b3a4b-212f45-272640-312244-3e1f47-4d194d",
    "f94144-f3722c-f8961e-f9844a-f9c74f-90be6d-43aa8b-4d908e-577590-277da1",
    "f6bd60-f7ede2-f5cac3-84a59d-f28482",
    "0081a7-00afb9-fdfcdc-fed9b7-f07167",
    "f4f1de-e07a5f-3d405b-81b29a-f2cc8f",
    "001219-005f73-0a9396-94d2bd-e9d8a6-ee9b00-ca6702-bb3e03-ae2012-9b2226",
    "ef476f-ffd166-06d6a0-118ab2-073b4c",
    "fec5bb-fcd5ce-fae1dd-f8edeb-e8e8e4-d8e2dc-ece4db-ffe5d9-ffd7ba-fec89a",
    "e63946-f1faee-a8dadc-457b9d-1d3557",
    "264653-2a9d8f-e9c46a-f4a261-e76f51"
  ]

  def pick_palette do
    Enum.random(@palettes)
    |> String.split("-")
    |> Enum.map(&hex_to_rgb/1)
    |> Enum.shuffle()
  end

  defp hex_to_rgb(hex) do
    <<r::binary-size(2), g::binary-size(2), b::binary-size(2)>> = hex
    rgb(String.to_integer(r, 16), String.to_integer(g, 16), String.to_integer(b, 16))
  end

  defp draw_flower(x, y, r_max, r_step, colors, base) do
    translate x, y do
      Enum.reduce_while(
        Stream.iterate(r_max, &(&1 - r_step)),
        0,
        fn r, idx ->
          if r <= r_max / 5,
            do: {:halt, idx},
            else: {:cont, petal_ring(r, r_max, colors, idx)}
        end
      )

      # most inner circle
      circle(0.0, 0.0, r_max / 5, fill: base)
      circle(0.0, 0.0, r_max / 5, stroke: rgb(0, 0, 0, 200))
    end
  end

  defp petal_ring(r, r_max, colors, idx0) do
    petals = :rand.uniform(26) + 4
    angle_step = 2 * :math.pi() / petals
    rotation = :math.pi() * r / r_max

    Enum.reduce(0..(petals - 1), idx0, fn p_idx, acc ->
      angle = p_idx * angle_step + rotation
      x1 = :math.cos(angle) * r
      y1 = :math.sin(angle) * r
      x2 = :math.cos(angle + angle_step) * r
      y2 = :math.sin(angle + angle_step) * r
      x = (x1 + x2) / 2
      y = (y1 + y2) / 2
      d = :math.sqrt(:math.pow(x1 - x2, 2) + :math.pow(y1 - y2, 2))

      petal_color = Enum.at(colors, rem(acc, 2))
      petal_arc(x, y, d, petal_color)
      acc + 1
    end)
  end

  defp petal_arc(cx, cy, r, color) do
    # steps = 16
    start_angle = :math.atan2(cy, cx) - :math.pi() / 2
    end_angle = :math.atan2(cy, cx) + :math.pi() / 2
    step = :math.pi() / 180

    points =
      Stream.iterate(start_angle, &(&1 + step))
      |> Stream.take_while(&(&1 <= end_angle))
      |> Enum.map(fn angle ->
        {cx + :math.cos(angle) * r / 2, cy + :math.sin(angle) * r / 2}
      end)

    polygon([{0.0, 0.0} | points], fill: color)
    polyline([{0.0, 0.0} | points], stroke: rgb(0, 0, 0))
  end

  def layer_circle(x, y, d, palette) do
    [base | petal_colors] = Enum.shuffle(palette)

    base_r = d / 2

    # subtle shadow/glow: lighter alpha and smaller blur radius
    blur_path(circle_path(x, y, base_r), base_r / 7,
      mode: :fill,
      fill: rgb(0, 0, 0, 100),
      padding: base_r / 2
    )

    # keep base disc crisp on top of the blur
    circle(x, y, base_r, fill: base)

    draw_flower(x, y, base_r / 1.5, base_r / 6.0, petal_colors, base)
  end

  defp circle_path(x, y, r) do
    Blendend.Path.new!() |> Blendend.Path.add_circle!(x, y, r)
  end

  def stream_scales(x, y, factor, max_w, fun) do
    if x <= max_w do
      fun.(x, y)
      stream_scales(x * factor, y * factor, factor, max_w, fun)
    end
  end
end

# ---------------------------------------------------------------------------
# Main sketch
# ---------------------------------------------------------------------------
w = 800
h = 800
alias BlendendPlaygroundPhx.Demos.FloralWave

draw w, h do
  palette = FloralWave.pick_palette()
  [bg | colors] = palette

  clear(fill: bg)
  clear(fill: rgb(0, 0, 0, 60), comp_op: :multiply)
  rows = 5
  offset = w / 5
  cell_h = (h - offset * 2) / rows
  max_w = w - offset * 2
  base_angle = :math.pi() / 180 * (180 / 12 + 7)

  Enum.each(0..rows, fn i ->
    ox = if rem(i, 2) == 0, do: offset, else: w - offset
    oy = offset + cell_h * i

    translate ox, oy do
      rot = if rem(i, 2) == 0, do: -base_angle / 2, else: -base_angle / 2 + :math.pi()

      rotate rot do
        x = 10.0
        y = x * :math.tan(base_angle / 2)
        d = :math.sqrt(x * x + y * y)
        scale_factor = (d + y) / (d - y)

        FloralWave.stream_scales(x, y, scale_factor, max_w, fn sx, sy ->
          FloralWave.layer_circle(sx, sy, sy * 2, colors)
        end)
      end
    end
  end)
end
