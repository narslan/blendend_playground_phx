# This example demonstrates different pattern extend modes.
# Tiles a single image across a 3x3 grid to compare pad, repeat, and reflect options.
alias Blendend.Image
alias Blendend.Style.Pattern, as: PatternStyle

modes = [
  :pad,
  :repeat,
  :reflect,
  :pad_x_repeat_y,
  :pad_x_reflect_y,
  :repeat_x_pad_y,
  :repeat_x_reflect_y,
  :reflect_x_pad_y,
  :reflect_x_repeat_y
]

panel_w = 260
panel_h = 260
gap = 20
cols = 3
rows = 3
total_w = cols * panel_w + (cols - 1) * gap
total_h = rows * panel_h + (rows - 1) * gap

draw total_w, total_h do
  fish = BlendendPlayground.Demos.Fish.data()
  {:ok, img} = Image.from_data(fish)
  {:ok, {img_w, img_h}} = Image.size(img)

  pat = PatternStyle.create!(img)

  # we want roughly 2 tiles across and 2 down
  scale_x = panel_w / 2.0 / img_w
  scale_y = panel_h / 2.0 / img_h
  scale = min(scale_x, scale_y)

  m =
    matrix do
      scale(scale, scale)
    end

  :ok = PatternStyle.set_transform(pat, m)

  Enum.with_index(modes, fn mode, idx ->
    row = div(idx, cols)
    col = rem(idx, cols)

    x_off = col * (panel_w + gap)
    y_off = row * (panel_h + gap)

    m =
      matrix do
        translate(x_off, y_off)
      end

    with_transform m do
      :ok = PatternStyle.set_extend(pat, mode)
      rect(0.0, 0.0, panel_w * 1.0, panel_h * 1.0, fill: pat)
    end
  end)
end
