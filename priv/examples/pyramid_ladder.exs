# Port of a p5.js sketch https://openprocessing.org/sketch/1352907

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
  num = 8
  d = w / num

  unit_tri = [
    {1.0, 0.0},
    {-0.5, :math.sqrt(3.0) / 2.0},
    {-0.5, -:math.sqrt(3.0) / 2.0}
  ]

  shadow_sigma = d / 5
  shadow_dx = cos(deg_to_rad.(3.0)) * d / 10.0
  shadow_dy = sin(deg_to_rad.(3.0)) * d / 10.0
  shadow_alpha = 0.15

  m =
    matrix do
      translate(width / 2, height / 2)
      rotate(rot)
      translate(-w / 2, -w / 2)
    end

  with_transform m do
    for j <- 0..(num - 1), i <- 0..(num - 1) do
      r = d
      s = r
      x = i * r * sin60 * 2
      y = j * (r + r * cos60)

      sep = rand_between_int(10, 50)
      dir = if :rand.uniform() > 0.5, do: -1, else: 1
      colors = Enum.shuffle(palette)

      m =
        matrix do
          translate(x, y)
          rotate(-:math.pi() / 6)
        end

      with_transform m do
        grad =
          radial_gradient 0, 0, 0, 0, 0, s do
            add_stop(0.0, Enum.at(colors, 0))
            add_stop(1.0, Enum.at(colors, 1))
          end

        Enum.reduce(sep..1//-1, 0.0, fn l, angle_acc ->
          inc = deg_to_rad.(map(l, sep, 0, 0, 10) * dir)
          angle_acc = angle_acc + inc
          t = s * l / sep
          cr = cos(angle_acc)
          sr = sin(angle_acc)

          [{ux1, uy1}, {ux2, uy2}, {ux3, uy3}] = unit_tri

          points = [
            {(ux1 * cr - uy1 * sr) * t, (ux1 * sr + uy1 * cr) * t},
            {(ux2 * cr - uy2 * sr) * t, (ux2 * sr + uy2 * cr) * t},
            {(ux3 * cr - uy3 * sr) * t, (ux3 * sr + uy3 * cr) * t}
          ]

          # Draw each triangle separately (like p5), otherwise the union fill
          # removes the spiral layering effect.
          translate(shadow_dx, shadow_dy) do
            polygon(points, fill: rgb(0, 0, 0), alpha: shadow_alpha)
          end

          polygon(points, fill: grad)

          angle_acc
        end)
      end

      x2 = x + cos30 * r
      y2 = y + sin30 * r

      m2 =
        matrix do
          translate(x2, y2)
          rotate(:math.pi() - :math.pi() / 6)
        end

      sep = rand_between_int(10, 50) * 2
      dir = if :rand.uniform() > 0.5, do: -1, else: 1

      with_transform m2 do
        grad =
          radial_gradient 0, 0, 0, 0, 0, s do
            add_stop(0.0, Enum.at(colors, 2))
            add_stop(1.0, Enum.at(colors, 3))
          end

        Enum.reduce(sep..1//-1, 0.0, fn l, angle_acc ->
          inc = deg_to_rad.(map(l, sep, 0, 0, 10) * dir)
          angle_acc = angle_acc + inc
          t = s * l / sep
          cr = cos(angle_acc)
          sr = sin(angle_acc)

          [{ux1, uy1}, {ux2, uy2}, {ux3, uy3}] = unit_tri

          points = [
            {(ux1 * cr - uy1 * sr) * t, (ux1 * sr + uy1 * cr) * t},
            {(ux2 * cr - uy2 * sr) * t, (ux2 * sr + uy2 * cr) * t},
            {(ux3 * cr - uy3 * sr) * t, (ux3 * sr + uy3 * cr) * t}
          ]

          translate(shadow_dx, shadow_dy) do
            polygon(points, fill: rgb(0, 0, 0), alpha: shadow_alpha)
          end

          polygon(points, fill: grad)

          angle_acc
        end)
      end
    end
  end
end
