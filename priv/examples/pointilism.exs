# This is a minimal template with palette support
use BlendendPlaygroundPhx.Calculation.Macros
alias BlendendPlaygroundPhx.Palette
alias Blendend.Path
width = 800
height = 800
pi = :math.pi()
deg_to_rad = fn deg -> deg * pi / 180.0 end

sin60 = :math.sin(pi / 3.0)
cos60 = :math.cos(pi / 3.0)
cos30 = :math.cos(pi / 6.0)
sin30 = :math.sin(pi / 6.0)

palette =
  Palette.fetch_random_source()
  |> Palette.fetch_random_palette()
  |> Map.get(:colors, [])
  |> Palette.from_hex_list_rgb()
  |> Enum.map(&rgb/1)

draw width, height do
  clear(fill: hsv(0, 0, 0.9))
  rot = rand_radian()
  w = sqrt(sq(width) + sq(height))
  num = 18
  r = w / num

  m =
    matrix do
      translate(width / 2, height / 2)
      rotate(rot)
      translate(-w / 2, -w / 2)
    end

  with_transform m do
    for j <- 0..(num - 1), i <- 0..(num - 1) do
  
      x = i * r * sin60 * 2
      y = j * (r + r * cos60)
      circle(x, y, 4, fill: Enum.random(palette))
    end
  end
end
