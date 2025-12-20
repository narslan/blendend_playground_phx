# This is the draft for a table layout. 
alias BlendendPlayground.Palette
alias BlendendPlayground.Gradients
width = 1500
height = 1000

draw width, height do
  clear(fill: rgb(0xF8, 0xF8, 0xF8))
  font = load_font("priv/fonts/AlegreyaSans-Regular.otf", 30.0)
  text(font, 22, 34, "Tables and Scales", fill: rgb(0, 0, 36))

  data = [
    ["File name", "Last modified", "Type", "Size"],
    ["a.txt", "3 Months ago", "TXT", "214 KB"],
    ["b.pdf", "1 Months ago", "PDF", "114 KB"],
    ["c.wav", "11 Months ago", "WAV", "21 MB"]
  ]

  s =
    Scale.Band.new(domain: data, range: [0, 200], padding_inner: 0.8, padding_outer: 0.2)

  base_x = 40
  base_y = 140
  pad = 10

  for row <- Scale.domain(s) do
    # Find height
    h = Scale.map(s, row)

    # column scale
    sc =
      Scale.Band.new(domain: row, range: [0, width], padding_inner: 0.5, padding_outer: 0.2)

    for col <- Scale.domain(sc) do
      w = Scale.map(sc, col)
      pad = sc.padding_inner * pad
      text(font, base_x + w, base_y + h - pad, col, fill: rgb(0, 0, 36))
    end

    line(base_x, base_y + h, width - base_x, base_y + h)
  end
end
