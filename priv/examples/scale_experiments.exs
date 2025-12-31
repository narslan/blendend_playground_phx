alias BlendendPlaygroundPhx.Palette
alias BlendendPlaygroundPhx.Gradients

draw 800, 800 do
  clear(fill: rgb(255, 255, 255))
  # https://observablehq.com/@d3/colorbrewer-splines
  palette =
    [
      "#8e0152",
      "#c51b7d",
      "#de77ae",
      "#f1b6da",
      "#fde0ef",
      "#f7f7f7",
      "#e6f5d0",
      "#b8e186",
      "#7fbc41",
      "#4d9221",
      "#276419"
    ]
    |> Palette.from_hex_list_rgb()

  fc = hd(palette)
  lc = List.last(palette)

  # box dimensions
  x0 = 40
  y0 = 40
  x1 = 720
  y1 = 100
  h = y1 - y0
  steps = 10

  label_font = load_font("priv/fonts/MapleMono-Regular.otf", 16.0)

  scale_quantize =
    Scale.Quantize.new(
      domain: [0, 1],
      range: palette
    )

  scale_oklab =
    Scale.Linear.new(
      domain: [0, 1],
      range: [fc, lc],
      interpolate: &Scale.Interpolator.oklab/2
    )

  scale_rgb = Scale.Linear.set_interpolate(scale_oklab, &Scale.Interpolator.rgb/2)
  scale_oklch = Scale.Linear.set_interpolate(scale_oklab, &Scale.Interpolator.oklch/2)

  eased_rgb =
    Scale.Interpolator.eased(
      &Scale.Interpolator.rgb/2,
      &Scale.Interpolator.smootherstep/1
    )

  scale_eased_rgb = Scale.Linear.set_interpolate(scale_oklab, eased_rgb)

  Gradients.linear_labeled_box_from_scale({x0, y0, x1, y1}, scale_quantize, "Quantize palette",
    steps: steps,
    label_font: label_font
  )

  Gradients.linear_labeled_box_from_scale({x0, y0 + h, x1, y1 + h}, scale_rgb, "LinearRGB",
    steps: steps,
    label_font: label_font
  )

  Gradients.linear_labeled_box_from_scale(
    {x0, y0 + 2 * h, x1, y1 + 2 * h},
    scale_eased_rgb,
    "LinearRGB + smootherstep",
    steps: steps,
    label_font: label_font
  )

  Gradients.linear_labeled_box_from_scale({x0, y0 + 3 * h, x1, y1 + 3 * h}, scale_oklab, "OKLab",
    steps: steps,
    label_font: label_font
  )

  Gradients.linear_labeled_box_from_scale({x0, y0 + 4 * h, x1, y1 + 4 * h}, scale_oklch, "OKLCH",
    steps: steps,
    label_font: label_font
  )
end
