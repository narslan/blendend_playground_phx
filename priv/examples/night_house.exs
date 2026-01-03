# https://openprocessing.org/sketch/2497472
use Blendend.Draw
use BlendendPlaygroundPhx.Calculation.Macros
alias BlendendPlaygroundPhx.Palette

defmodule BlendendPlaygroundPhx.Demos.NightHouse do
  # drawHouse(x, y + hStep + ny, xStep, h, palette);
  def draw_house(x, y, w, h, palette) do
    palette = Enum.shuffle(palette)

    w2 = rand_between(w / 8, w / 2)
    bool = if :rand.uniform() > 0.5, do: true, else: false

    translate x, y do
      if bool do
        translate(w, 0)
        scale(-1, 1)
      end

      scl = rand_between(0.75, 1.25)
      scale(scl, 1)
      # draw chimneys
      if :rand.uniform() > 0.5 do
        {ch, cs, cv} = List.last(palette)
        c = hsv(ch, cs, max(cv - 0.2, 0))
        y0_temp = -rand_between(w / 3, w / 8)
        x1_temp = -rand_between(w / 15, w / 10)
        rect(w / 2, y0_temp, x1_temp, h, fill: c)
      end

      p =
        path do
          move_to(0, w2)
          line_to(w / 4, 0)
          line_to(w * 3 / 4, 0)
          line_to(w, w2)
          line_to(w, h)
          line_to(0, h)
          close()
        end

      fill_path(p, fill: hsv(0, 0, 1.0))

      shadow_path(p, w / 8, w / 8, w / 3, fill: hsv(0, 0, 0, 33), resolution: 0.1)

      # roof
      {ch, cs, cv} = Enum.at(palette, 0)

      grad2 =
        linear_gradient 0, 0, 0, w2 do
          add_stop(0.0, hsv(ch, cs, cv))
          add_stop(1.0, hsv(ch, cs, max(cv - 0.2, 0)))
        end

      p2 =
        path do
          move_to(w / 4, 0)
          line_to(w * 3 / 4, 0)
          line_to(w, w2)
          line_to(w / 2, w2)
          close()
        end

      fill_path(p2, fill: grad2)

      # fascia 1
      {ch, cs, cv} = Enum.at(palette, 1)

      grad3 =
        linear_gradient 0, w2, 0, h do
          add_stop(0.0, hsv(ch, cs, cv))
          add_stop(0.1, hsv(ch, cs, max(cv - 0.2, 0)))
        end

      p3 =
        path do
          move_to(w / 2, w2)
          line_to(w, w2)
          line_to(w, h)
          line_to(w / 2, h)
          close()
        end

      fill_path(p3, fill: grad3)

      # fascia 2
      {h3, s3, v3} = Enum.at(palette, 2)
      {h4, s4, v4} = Enum.at(palette, 3)

      grad4 =
        linear_gradient 0, 0, 0, h do
          add_stop(0.0, hsv(h3, s3, v3))
          add_stop(1 / 15, hsv(h4, s4, v4))
        end

      p4 =
        path do
          move_to(0, w2)
          line_to(w / 4, 0)
          line_to(w / 2, w2)
          line_to(w / 2, h)
          line_to(0, h)
          close()
        end

      fill_path(p4, fill: grad4)

      {h5, s5, v5} = Enum.at(palette, -2)
      x_translate_amount = if :rand.uniform() > 0.5, do: 0, else: w / 2
      translate(x_translate_amount, w2)
      h2 = w / 2 * rand_between(0.5, 1)
      translate(w / 4, h2)
      rect_center(0, 0, w / 4, h2, fill: hsv(h5, s5, v5), comp_op: :color_burn)
    end
  end

  def walk_rows(y0, height, fun) do
    if y0 < height do
      # compute current step
      y_step = map(y0, height / 4, height, height / 50, height / 20)
      fun.(y0)
      walk_rows(y0 + y_step, height, fun)
    end
  end

  def walk_cols(x0, width, step_base_fun, house_fun) do
    if x0 < width do
      x_step_base = step_base_fun.()
      x_step = rand_between(x_step_base / 2, x_step_base * 2)
      house_fun.(x0, x_step)
      walk_cols(x0 + x_step, width, step_base_fun, house_fun)
    end
  end
end

width = 800
height = 800
alias BlendendPlaygroundPhx.Demos.NightHouse

draw width, height do
  gradient =
    linear_gradient 0, 0, 0, height do
      add_stop(0.0, hsv(220, 0.8, 0.0))
      add_stop(0.4, hsv(220, 0.8, 0.7))
    end

  clear(fill: gradient)

  # Star field: sample positions uniformly, then keep/brighten them based on
  # signed value-noise so stars clump in brighter patches.
  star_seed = :rand.uniform() * 1000.0
  # Sample noise on a coarse grid and spawn stars per cell (much cheaper).
  cell = 32
  max_y = height * 0.9
  noise_scale = 0.015

  for gx <- 0..div(width, cell),
      gy <- 0..div(trunc(max_y), cell) do
    cx = gx * cell + cell / 2
    cy = gy * cell + cell / 2

    # Fade out toward horizon to reduce stars near the bottom.
    horizon_falloff = map(cy, 0, max_y, 1.0, 0.65)

    n =
      noise2_signed(cx * noise_scale, cy * noise_scale, star_seed)
      |> then(&((&1 + 1.0) / 2.0 * horizon_falloff))

    # Decide how many stars to place in this cell based on noise.
    stars_here =
      cond do
        n > 0.75 -> 1
        n > 0.6 -> 1
        true -> 0
      end

    if stars_here > 0 do
      for _ <- 1..stars_here do
        x = gx * cell + :rand.uniform() * cell
        y = gy * cell + :rand.uniform() * cell
        alpha = trunc(80 + n * 170) |> min(255)
        radius = 0.6 + n * 1.2
        circle(x, y, radius, fill: rgb(255, 255, 255, alpha))
      end
    end
  end

  w = height / 10 / 1.5
  h = height * 2
  noise_scale = 0.01

  palette =
    Palette.fetch_random_palette("artists")
    |> Map.get(:colors, [])
    |> Palette.from_hex_list_hsv()

  NightHouse.walk_rows(height / 4, height, fn y ->
    x_step_base = map(y, height / 4, height, w / 2, w * 3)

    NightHouse.walk_cols(0.0, width, fn -> x_step_base end, fn x, x_step ->
      n_raw = noise2_signed(x * noise_scale, y * noise_scale, 0.0)
      # Value-noise has a wider distribution than classic Perlin; compress toward
      # 0.5 to avoid overly tall houses.
      t = (n_raw + 1.0) / 2.0
      t = 0.5 + (t - 0.5) * 0.2
      ny = t * height / 2

      h_step =
        map(y, height / 4, height, height / 100, height / 10) *
          if :rand.uniform() > 0.5, do: -1, else: 1

      NightHouse.draw_house(x, y + h_step + ny, x_step, h, palette)
    end)

    gradient2 =
      linear_gradient 0, y, 0, height do
        add_stop(1.0, hsv(0, 0, 0, 1))
        add_stop(0.0, hsv(0, 0, 0, 0))
      end

    clear(fill: gradient2)
  end)
end
