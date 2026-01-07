# Compositing operator demo / mini tutorial.
#
# Each tile draws the same destination (circle) and source (square).
# The source square is drawn with `comp_op: ...` so you can compare how each operator blends.

alias BlendendPlaygroundPhx.Tiler

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
tile_h = 170
gap = 18

pad_x = 34
header_h = 88
pad_bottom = 34

swatch_w = 320
swatch_gap = 22

grid_inner_w = cols * tile_w + (cols - 1) * gap
grid_inner_h = rows * tile_h + (rows - 1) * gap

grid_w = pad_x * 2 + grid_inner_w
w = grid_w + swatch_gap + swatch_w
h = header_h + pad_bottom + grid_inner_h

scheme = palette("artists.VanGogh")

bg = palette_named(scheme, :background) || rgb(244, 246, 250)
ink = scheme |> palette_at(4) |> alpha(255)

dest = scheme |> palette_at(1) |> alpha(220)
src = scheme |> palette_at(3) |> alpha(210)

tiler =
  Tiler.grid(rows, cols, {pad_x, header_h, grid_inner_w, grid_inner_h},
    x_padding_inner: gap / (tile_w + gap),
    y_padding_inner: gap / (tile_h + gap),
    padding_outer: 0.0
  )

draw w, h do
  clear(fill: bg)

  title_font = font("AlegreyaSans", 30.0)
  subtitle_font = font("AlegreyaSans", 14.0)
  desc_font = font("AlegreyaSans", 12.0)
  label_font = font("MapleMono", 12.0)

  text(title_font, pad_x, 44, "Compositing operators", fill: ink)

  text(subtitle_font, pad_x, 68, "Ziel (Kreis) + Quelle (Quadrat mit comp_op)", fill: ink)

  line(pad_x, 78, grid_w - pad_x, 78, stroke: alpha(ink, 180), stroke_width: 1.0)

  debug_palette_swatch(scheme,
    at: {grid_w + swatch_gap, header_h},
    width: swatch_w,
    max: 12,
    chip: 14,
    gap: 6,
    font: label_font,
    show_hsv: true,
    highlights: [0, 3]
  )

  checker = 14

  for {op, idx} <- Enum.with_index(operators) do
    col = rem(idx, cols)
    row = div(idx, cols)

    cell = Tiler.cell!(tiler, row, col)

    translate cell.x, cell.y do
      round_rect(0, 0, cell.w, cell.h, 18, 18,
        stroke: scheme.stroke,
        stroke_width: 2.0
      )

      op_label = ":" <> Atom.to_string(op)
      desc = Map.get(descriptions, op, "")

      text(label_font, 16, 24, op_label, fill: ink)
      text(desc_font, 16, 42, desc, fill: alpha(ink, 190))

      content_x = 16
      content_y = 54
      content_w = cell.w - 32
      content_h = cell.h - 70

      bg_cols = trunc(content_w / checker)
      bg_rows = trunc(content_h / checker)

      for j <- 0..bg_rows, i <- 0..bg_cols do
        fill =
          if rem(i + j, 2) == 0 do
            rgb(0, 0, 52)
          else
            rgb(0, 0, 240)
          end

        rect(content_x + i * checker, content_y + j * checker, checker, checker, fill: fill)
      end

      dx = content_x + content_w * 0.42
      dy = content_y + content_h * 0.58
      circle(dx, dy, content_w * 0.26, fill: dest)

      sx = content_x + content_w * 0.64
      sy = content_y + content_h * 0.42

      translate sx, sy do
        rotate(:math.pi() / 10)
        rect_center(0, 0, content_w * 0.46, content_w * 0.46, fill: src, comp_op: op)
      end
    end
  end
end
