# This is a table layout demo built on `BlendendPlaygroundPhx.Tiler`.
alias BlendendPlaygroundPhx.Tiler

width = 1920
height = 820

draw width, height do
  scheme = palette("artists.Benedictus")

  bg = scheme |> palette_at(3)
  ink = scheme |> palette_at(4)
  title_color = scheme |> palette_at(4)
  subtitle_color = scheme |> palette_at(4)
  grid = alpha(ink, 10)
  header_bg = scheme |> palette_at(0) |> alpha(140)
  stripe_bg = scheme |> palette_at(2) |> alpha(18)

  clear(fill: bg)

  title_font = font("AlegreyaSans", 60.0, "Black")
  subtitle_font = font("AlegreyaSans", 24.0, "BoldItalic")
  header_font = font("AlegreyaSans", 24.0, "Bold")
  cell_font = font("MapleMono", 30.0, "Thin")
  kaishu = font("Fandolkai", 60.0, "Bold") 
  text(title_font, width / 2 - 50, 52, "Tables", fill: title_color)
  text(subtitle_font, 40, 78, "Mandarin tones", fill: subtitle_color)

  data = [
    ["今天", "Last modified", "Type", "Size"],
    ["File name", "Last modified", "Type", "Size"],
    ["File name", "Last modified", "Type", "Size"],
    ["File name", "Last modified", "Type", "Size"]
  ]

  table_x = 40
  table_y = 110
  table_w = width - table_x * 2
  table_h = height - table_y - 60

  tiler =
    Tiler.table(data, {table_x, table_y, table_w, table_h})

  row_h = tiler.cell_h
  pad_x = 14
  pad_y = 30


  for col <- tiler.cols do
    x = Scale.map(tiler.x_scale, col)
    line(x, table_y, x, table_y + table_h, stroke: grid, stroke_width: 4.0)
  end

  line(table_x, table_y + table_h, table_x + table_w, table_y + table_h,
    stroke: grid,
    stroke_width: 4.0
  )

  line(table_x + table_w, table_y, table_x + table_w, table_y + table_h,
    stroke: grid,
    stroke_width: 4.0
  )

  for row <- tiler.rows do
    for col <- tiler.cols do
      value = Tiler.value(tiler, row, col, "")
      rect = Tiler.cell!(tiler, row, col)
      inner = Tiler.inset(rect, {pad_x, pad_y})

      text_font =  kaishu
      fill = if row == 0, do: ink, else: alpha(ink, 220)
      text(text_font, inner.x, inner.y + inner.h * 0.72, to_string(value), fill: fill)
    end
  end
end
