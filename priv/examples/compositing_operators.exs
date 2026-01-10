# Compositing operator demo / mini tutorial.
#
# Each tile draws the same destination (yellow) and source (cyan).
# The source square is drawn with `comp_op: ...` so you can compare how each operator blends.

alias BlendendPlaygroundPhx.Tiler

operators = [
  :src_over,
  :src_copy,
  :src_in,
  :src_out,
  :src_atop,
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

cols = 6
rows = Integer.ceil_div(length(operators), cols)

tile_w = 210
tile_h = 210
gap = 18

pad_x = 34
header_h = 88
pad_bottom = 34

grid_inner_w = cols * tile_w + (cols - 1) * gap
grid_inner_h = rows * tile_h + (rows - 1) * gap

grid_w = pad_x * 2 + grid_inner_w
w = grid_w
h = header_h + pad_bottom + grid_inner_h

ink = rgb(10, 10, 35)
stroke_color = rgb(0, 0, 10)
src = rgb(104, 199, 232)
dest = rgb(255, 220, 1)

tiler =
  Tiler.grid(rows, cols, {pad_x, header_h, grid_inner_w, grid_inner_h},
    x_padding_inner: gap / (tile_w + gap),
    y_padding_inner: gap / (tile_h + gap)
  )

draw w, h do
  title_font = font("AlegreyaSans", 40.0, "Bold")
  label_font = font("MapleMono", 16.0, "Bold")

  text(title_font, pad_x + 480, 44, "Compositing operators", fill: ink)

  line(pad_x, 78, grid_w - pad_x, 78, stroke: alpha(ink, 180), stroke_width: 1.0)

  for {op, idx} <- Enum.with_index(operators) do
    col = rem(idx, cols)
    row = div(idx, cols)

    cell = Tiler.cell!(tiler, row, col)

    translate cell.x, cell.y do
      round_rect(0, 0, cell.w, cell.h, 18, 18,
        stroke: stroke_color,
        stroke_width: 2.0
      )

      op_label = ":" <> Atom.to_string(op)
      text(label_font, 16, 24, op_label, fill: ink)

      content_w = cell.w - 32
      content_h = cell.h - 70

      translate 20, 40 do
        rect(0, 0, content_w * 0.75, content_h * 0.75, fill: dest)

        rect(
          content_w - content_w * 0.75,
          content_h - content_h * 0.75,
          content_w * 0.75,
          content_h * 0.75, fill: src, comp_op: op)
      end
    end
  end
end
