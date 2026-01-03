# port of https://openprocessing.org/sketch/1564766
# Please download the NotoSansCJKjp-Black font under the directory "priv/fonts" of this project.
# https://github.com/notofonts/noto-cjk/raw/refs/heads/main/Sans/OTF/Japanese/NotoSansCJKjp-Black.otf 
alias Blendend.Style.Gradient
alias Blendend.Text.{Face, Font, GlyphBuffer, GlyphRun}
alias Blendend.{Matrix2D, Path}

width = 800
height = 800

design_system = [
  %{
    name: "Inochi",
    colors: ["#E60012", "#D2D7DA", "#0068B7", "#FFFFFF"]
  },
  %{name: "Nizami", colors: ["#034AA6", "#72B6F2", "#73BFB1", "#F2A30F", "#F26F63"]},
  %{
    name: "Pissaro",
    colors: [
      "#134130",
      "#4c825d",
      "#8cae9e",
      "#8dc7dc",
      "#508ca7",
      "#1a5270",
      "#0e2a4d"
    ]
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

block_codepoints = Enum.to_list(0x2590..0x2599)

hex_to_rgb = fn
  "#" <> <<r::binary-size(2), g::binary-size(2), b::binary-size(2)>> ->
    {String.to_integer(r, 16), String.to_integer(g, 16), String.to_integer(b, 16)}
end

design_system =
  Enum.map(design_system, fn %{name: name, colors: colors} ->
    %{
      name: name,
      colors:
        Enum.map(colors, fn hex ->
          {r, g, b} = hex_to_rgb.(hex)
          rgb(r, g, b)
        end)
    }
  end)

font_path =
  "priv/fonts/NotoSansCJKjp-Black.otf"

face = Face.load!(font_path)
font = Font.create!(face, 1.0)
identity = Matrix2D.identity!()

glyph_paths =
  Enum.reduce(block_codepoints, %{}, fn cp, acc ->
    str = <<cp::utf8>>

    gb =
      GlyphBuffer.new!()
      |> GlyphBuffer.set_utf8_text!(str)
      |> Font.shape!(font)

    metrics = Font.get_text_metrics!(font, gb)

    x0 = Map.fetch!(metrics, "bbox_x0") * 1.0
    y0 = Map.fetch!(metrics, "bbox_y0") * 1.0
    x1 = Map.fetch!(metrics, "bbox_x1") * 1.0
    y1 = Map.fetch!(metrics, "bbox_y1") * 1.0

    dx = -(x0 + x1) / 2
    dy = -(y0 + y1) / 2

    run = GlyphRun.new!(gb)

    path =
      Path.new!()
      |> Font.get_glyph_run_outlines!(font, run, identity)
      |> Path.translate!(dx, dy)

    Map.put(acc, cp, path)
  end)

draw width, height do
  clear(fill: rgb(242, 242, 242))

  w = :math.sqrt(2) * width
  work_path = Path.new!()

  translate(width / 2, height / 2) do
    rotate(:math.pi() / 4) do
      translate(-w / 2, -w / 2) do
        offset = -w / 15
        x0 = offset
        y0 = offset
        d = w - offset * 2
        min_d = d / 15

        random_palette = fn ->
          scheme = Enum.random(design_system)

          scheme.colors
          |> Enum.shuffle()
        end

        rand_bool = fn -> :rand.uniform() > 0.5 end
        rand_path = fn -> Map.fetch!(glyph_paths, Enum.random(block_codepoints)) end

        draw_block = fn x, y, tile_w ->
          base_palette = random_palette.()

          Enum.each(1..3, fn _ ->
            palette = Enum.shuffle(base_palette)
            palette_len = length(palette)

            c1 = Enum.at(palette, 0)
            c2 = Enum.at(palette, rem(1, palette_len))
            c3 = Enum.at(palette, rem(2, palette_len))

            unit_path = rand_path.()
            sx = if(rand_bool.(), do: -tile_w, else: tile_w) * 1.0
            sy = tile_w * 1.0
            mtx = Matrix2D.new!([sx, 0.0, 0.0, sy, x * 1.0, y * 1.0])

            Path.clear!(work_path)
            Path.add_path!(work_path, unit_path, mtx)

            shadow_path(work_path, 0.0, 0.0, tile_w / 4,
              fill: rgb(0, 0, 0),
              alpha: 0.165,
              resolution: 0.1
            )

            grad =
              if rand_bool.() do
                Gradient.linear!(-tile_w / 2, 0.0, tile_w / 2, 0.0)
              else
                Gradient.linear!(0.0, -tile_w / 2, 0.0, tile_w / 2)
              end
              |> Gradient.add_stop!(0.0, c1)
              |> Gradient.add_stop!(0.5, c3)
              |> Gradient.add_stop!(1.0, c2)

            fill_path(work_path, fill: grad)
          end)
        end

        separate_grid = fn separate_grid, x, y, size, min_size ->
          step = Enum.random(2..4)
          cell = size / step

          Enum.each(0..(step - 1), fn j ->
            Enum.each(0..(step - 1), fn i ->
              nx = x + i * cell
              ny = y + j * cell

              if :rand.uniform() > 0.98 or cell < min_size do
                draw_block.(nx + cell / 2, ny + cell / 2, cell)
              else
                separate_grid.(separate_grid, nx, ny, cell, min_size)
              end
            end)
          end)
        end

        separate_grid.(separate_grid, x0, y0, d, min_d)
      end
    end
  end
end
