# Compositing operator demo / mini tutorial.
#
# Each tile draws the same destination (blue circle) and source (rose square).
# The source square is drawn with `comp_op: ...` so you can compare how each operator blends.

operators = [
  :src_over,
  :src_copy,
  :src_in,
  :src_out,
  :dst_over,
  :dst_copy,
  :dst_in,
  :dst_out,
  :dst_atop,
  :difference,
  :multiply,
  :screen,
  :overlay,
  :xor,
  :clear,
  :plus,
  :minus,
  :modulate,
  :darken,
  :lighten,
  :color_dodge,
  :color_burn,
  :linear_burn,
  :pin_light,
  :hard_light,
  :soft_light,
  :exclusion
]

descriptions = %{
  src_over: "Standard (over)",
  src_copy: "Ersetzt Ziel",
  src_in: "Quelle in Ziel",
  src_out: "Quelle außerhalb Ziel",
  dst_over: "Hinter Ziel",
  dst_copy: "Nur Ziel",
  dst_in: "Ziel in Quelle",
  dst_out: "Ziel außerhalb Quelle",
  dst_atop: "Ziel atop Quelle",
  clear: "Clear · löscht",
  xor: "XOR · ohne Overlap",
  plus: "Plus · additiv",
  minus: "Minus · subtraktiv",
  modulate: "Modulate · multipliziert",
  multiply: "Multiply · dunkler",
  screen: "Screen · heller",
  overlay: "Overlay · Kontrast",
  difference: "Difference · invertiert",
  darken: "Darken · dunklere Werte",
  lighten: "Lighten · hellere Werte",
  color_dodge: "Color Dodge · Highlights",
  color_burn: "Color Burn · Schatten",
  linear_burn: "Linear Burn",
  pin_light: "Pin Light",
  hard_light: "Hard Light",
  soft_light: "Soft Light",
  exclusion: "Exclusion"
}

cols = 6
rows = Integer.ceil_div(length(operators), cols)

tile_w = 210
tile_h = 210
gap = 38

pad_x = 34
header_h = 188
pad_bottom = 34

swatch_w = 240
swatch_gap = 22

w = pad_x * 2 + cols * tile_w + (cols - 1) * gap + swatch_gap + swatch_w
h = header_h + pad_bottom + rows * tile_h + (rows - 1) * gap 

scheme = palette("artists.Cross")
  dest = scheme |> hell() |> alpha(120)
src = scheme |> palette_at(1) |> alpha(240)

draw w, h do
  clear(fill: hsv(65, 0.1, 0.8))

  title_font = font("AlegreyaSans", 80.0, "Bold")
  subtitle_font = font("AlegreyaSans", 28.0, "Black")
  desc_font = font("AlegreyaSans", 32.0)
  label_font = font("MapleMono", 32.0)
  swatch_font = font("MapleMono", 18.0)

  text(title_font, pad_x + 400, 120, "Compositing operators", fill: scheme |> palette_at(1))


  line(pad_x, 78, w - pad_x, 78, stroke: rgb(203, 213, 225), stroke_width: 1.0)

  debug_palette_swatch(scheme,
    at: {w - pad_x - swatch_w, header_h},
    width: swatch_w,
    max: 12,
    chip: 14,
    gap: 6,
    font: swatch_font,
    highlights: [0, 3]
  )

  checker = 14

  for {op, idx} <- Enum.with_index(operators) do
    col = rem(idx, cols)
    row = div(idx, cols)

    x0 = pad_x + col * (tile_w + gap)
    y0 = header_h + row * (tile_h + gap)

    translate x0, y0 do
      round_rect(0, 0, tile_w, tile_h, 18, 18,
        fill: rgb(255, 255, 255, 240),
        stroke: rgb(203, 213, 225),
        stroke_width: 1.0
      )

      op_label = ":" <> Atom.to_string(op)
      desc = Map.get(descriptions, op, "")

      text(label_font, 10, 24, op_label, fill: rgb(30, 41, 59))
      text(desc_font, 10, 52, desc, fill: scheme.stroke)

      content_x = 16
      content_y = 64
      content_w = tile_w - 32
      content_h = tile_h - 70

      bg_cols = trunc(content_w / checker)
      bg_rows = trunc(content_h / checker)

      for j <- 0..bg_rows, i <- 0..bg_cols do
        fill =
          if rem(i + j, 2) == 0 do
            rgb(248, 250, 252)
          else
            rgb(226, 232, 240)
          end

        rect(content_x + i * checker, content_y + j * checker, checker, checker, fill: fill)
      end

      # Destination (blue) first.
      dx = content_x + content_w * 0.42
      dy = content_y + content_h * 0.58
      circle(dx, dy, content_w * 0.26, fill: dest)

      # Source (rose) on top, blended via `comp_op`.
      sx = content_x + content_w * 0.64
      sy = content_y + content_h * 0.42

      translate sx, sy do
        rotate(:math.pi() / 10)
        rect_center(0, 0, content_w * 0.46, content_w * 0.46, fill: src, comp_op: op)
      end
    end
  end
end
