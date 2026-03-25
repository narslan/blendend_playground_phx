alias Blendend.Text.{Face, Font}
alias BlendendPlaygroundPhx.Text.InlineLayout

width = 1280
height = 960

samples = [
  {"Water", [{:text, "H"}, {:script, sub: "2"}, {:text, "O"}]},
  {"Pythagoras",
   [
     {:text, "x"},
     {:script, sup: "2"},
     {:text, " + y"},
     {:script, sup: "2"},
     {:text, " = z"},
     {:script, sup: "2"}
   ]},
  {"Sulfate", [{:text, "SO"}, {:script, sub: "4"}, {:script, sup: "2-"}]},
  {"Ammonium", [{:text, "NH"}, {:cluster, [sup: "+", sub: "4"]}]},
  {"Logarithm", [{:text, "log"}, {:script, sub: "2"}, {:text, "(n)"}]}
]

draw width, height do
  clear(fill: rgb(12, 17, 29))

  face = Face.load!("priv/fonts/Alegreya-Regular.otf")
  display_font = Font.create!(face, 74.0)
  title_font = Font.create!(face, 38.0)
  label_font = font("Maplemono", 20.0)

  canvas = Blendend.Draw.get_canvas()
  paper = rgb(236, 242, 248)
  ink = rgb(247, 250, 252)
  accent = rgb(120, 198, 255)
  guide = rgb(71, 101, 135, 170)
  panel = rgb(22, 31, 49, 220)

  text(
    title_font,
    72,
    86,
    "Manual subscript/superscript layout with Blendend",
    fill: paper
  )

  text(
    label_font,
    72,
    124,
    "Each script cluster is shaped separately, shifted on the baseline, and advanced by its widest run.",
    fill: rgb(155, 181, 206)
  )

  Enum.with_index(samples)
  |> Enum.each(fn {{label, tokens}, index} ->
    panel_y = 170 + index * 140
    baseline_y = panel_y + 80

    rect(56, panel_y, width - 112, 108, fill: panel)
    line(88, baseline_y, width - 96, baseline_y, stroke: guide, stroke_width: 1.5)

    text(label_font, 88, panel_y + 34, label, fill: accent)
    text(label_font, width - 180, panel_y + 34, "baseline", fill: guide)

    InlineLayout.layout_inline(
      tokens,
      display_font,
      190,
      baseline_y,
      canvas: canvas,
      face: face,
      fill: ink,
      script_scale: 0.62,
      superscript_rise: 28.0,
      subscript_drop: 18.0,
      cluster_gap: 4.0
    )
  end)
end
