# port of https://openprocessing.org/sketch/1562342
# Please download the NotoSansCJKjp-Black font under the directory "priv/fonts" of this project.
# https://github.com/notofonts/noto-cjk/raw/refs/heads/main/Sans/OTF/Japanese/NotoSansCJKjp-Black.otf 
alias Blendend.Style.Gradient
alias Blendend.Text.{Font, GlyphBuffer, GlyphRun}
alias Blendend.{Matrix2D, Path}

width = 800
height = 800

design_system = [
  %{
    name: "Inochi",
    colors: ["#E60012", "#D2D7DA", "#0068B7", "#FFFFFF"]
  },
  %{
    name: "Umi",
    colors: ["#0068B7", "#31ACE3", "#00A59E", "#C9E0B8", "#A78EC3", "#FFFFFF"]
  },
  %{
    name: "Noyama",
    colors: ["#0068B7", "#99C41E", "#00A59E", "#C9E0B8", "#D9DE00", "#FFFFFF"]
  },
  %{
    name: "Hikari",
    colors: ["#E60012", "#F2A800", "#EC8632", "#FCD700", "#E95D19", "#FFFFFF"]
  }
]

hex_to_rgb = fn
  "#" <> <<r::binary-size(2), g::binary-size(2), b::binary-size(2)>> ->
    {String.to_integer(r, 16), String.to_integer(g, 16), String.to_integer(b, 16)}
end

font_path =
  "priv/fonts/NotoSansCJKjp-Black.otf"

scheme = Enum.random(design_system)
palette =
  scheme.colors
  |> Enum.shuffle()
  |> Enum.map(fn hex ->
    {r, g, b} = hex_to_rgb.(hex)
    rgb(r, g, b)
  end)

random_row = fn cols ->
  1..cols
  |> Enum.map(fn _ ->
    cp = 0x25A0 + :rand.uniform(10) - 1
    <<cp::utf8>>
  end)
  |> IO.iodata_to_binary()
end

draw width, height do
  clear(fill: rgb(220, 220, 220))

  w = :math.sqrt(width * width + height * height) * 1.0
  tsize = w / 10.0

  cols = trunc(w / tsize) + 1
  rows = trunc(w / tsize) + 1
  line_count = rows + 2

  font = load_font(font_path, tsize)
  identity = Matrix2D.identity!()

  translate(width / 2, height / 2) do
    rotate(:math.pi() / 4) do
      translate(-w / 2, -w / 2) do
        for layer_idx <- 0..(length(palette) - 1) do
          layer_palette = Enum.shuffle(palette)
          palette_len = length(layer_palette)

          c1 = Enum.at(layer_palette, layer_idx)
          c2 = Enum.at(layer_palette, rem(layer_idx + 1, palette_len))
          c3 = Enum.at(layer_palette, rem(layer_idx + 2, palette_len))

          for row_idx <- 0..(line_count - 1) do
            row_text = random_row.(cols)

            gb =
              GlyphBuffer.new!()
              |> GlyphBuffer.set_utf8_text!(row_text)
              |> Font.shape!(font)

            run = GlyphRun.new!(gb)

            row_path = Path.new!()
            :ok = Font.get_glyph_run_outlines(font, run, identity, row_path)

            translate(0.0, -tsize / 2 + tsize * row_idx) do
              shadow_path(row_path, 0.0, 0.0, tsize / 12.0,
                fill: rgb(0, 0, 0),
                alpha: 33.0 / 255.0,
                resolution: 0.4          ) 

              grad =
                if rem(row_idx, 2) == 0 do
                  Gradient.linear!(w, 0.0, 0.0, 0.0)
                else
                  Gradient.linear!(0.0, 0.0, w, 0.0)
                end
                |> Gradient.add_stop!(0.0, c1)
                |> Gradient.add_stop!(0.5, c3)
                |> Gradient.add_stop!(1.0, c2)

              fill_path(row_path, fill: grad)
            end
          end
        end
      end
    end
  end
end
