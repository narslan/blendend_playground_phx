# circle of fifths
alias BlendendPlaygroundPhx.Palette
use Blendend.Draw
width = 1500
height = 1500

draw width, height do
  [c1, c2, _c3, c4, _c5 | _] =
    Palette.palette_by_name("tundra.tundra2")
    |> Map.get(:colors, [])
    |> Palette.from_hex_list_rgb()
    |> Enum.map(fn {r, g, b} -> rgb(r, g, b) end)

  clear(fill: rgb(250, 250, 250, 250))

  music_font_size = 60
  music_font = font("BravuraText", music_font_size)
  label_font_size = 60.0
  label_font = font("Alegreya", label_font_size)

  staff_scale = 24.0
  line_spacing = staff_scale * 0.8
  note_step = line_spacing / 2.4

  staff_color = c1
  accidental_color = c2
  clef_color = staff_color
  major_label_color = c2
  minor_label_color = c2

  center_x = width / 2
  center_y = height / 2
  base_radius = max(width, height) / 3

  # Glyphs for accidentals.
  sharp = "\uE262"
  flat = "\uE260"
  double_flat = "\uE264"
  double_sharp = "\uE263"
  # Accent ring to frame the key signatures.
  ring_outer = base_radius * 1.5
  ring_inner = base_radius * 0.6

  ring_grad =
    radial_gradient center_x, center_y, ring_outer, center_x, center_y, ring_inner do
      add_stop(0.0, hsv(145, 0.1, 0.92, 100))
      add_stop(0.6, hsv(185, 0.5, 0.5, 0))
      add_stop(1.0, hsv(240, 1.0, 1.0, 25))
    end

  circle(center_x, center_y, ring_outer, fill: ring_grad)

  # Positions (in half-line steps) relative to the middle line (B). Positive is upward.
  pitch_y_steps = %{
    b_flat: -3.0,
    b_sharp: -3.0,
    b_double_flat: -3.0,
    c_flat: -2.0,
    c_sharp: -2.0,
    d_flat: -1.0,
    d_sharp: -1.0,
    e_flat: -0.5,
    e_sharp: -0.5,
    f_flat: -6.0,
    f_sharp: 0.0,
    f_double_sharp: 1.0,
    g_flat: -5.0,
    g_sharp: 2.0,
    a_flat: -4.0,
    a_sharp: -4.0
  }

  # Key definitions as pitch lists.
  keys = %{
    c_major: [],
    g_major: [:f_sharp],
    d_major: [:f_sharp, :c_sharp],
    a_major: [:f_sharp, :c_sharp, :g_sharp],
    e_major: [:f_sharp, :c_sharp, :g_sharp, :d_sharp],
    b_major: [:f_sharp, :c_sharp, :g_sharp, :d_sharp, :a_sharp],
    f_sharp_major: [:f_sharp, :c_sharp, :g_sharp, :d_sharp, :a_sharp, :e_sharp],
    c_sharp_major: [:f_sharp, :c_sharp, :g_sharp, :d_sharp, :a_sharp, :e_sharp, :b_sharp],
    g_sharp_major: [:c_sharp, :g_sharp, :d_sharp, :a_sharp, :e_sharp, :b_sharp, :f_double_sharp],
    f_major: [:b_flat],
    b_flat_major: [:b_flat, :e_flat],
    e_flat_major: [:b_flat, :e_flat, :a_flat],
    a_flat_major: [:b_flat, :e_flat, :a_flat, :d_flat],
    d_flat_major: [:b_flat, :e_flat, :a_flat, :d_flat, :g_flat],
    g_flat_major: [:b_flat, :e_flat, :a_flat, :d_flat, :g_flat, :c_flat],
    c_flat_major: [:b_flat, :e_flat, :a_flat, :d_flat, :g_flat, :c_flat, :f_flat],
    f_flat_major: [:e_flat, :a_flat, :d_flat, :g_flat, :c_flat, :f_flat, :b_double_flat]
  }

  # Order to render, rotated so C major sits at the top
  key_order = [
    :c_major,
    :g_major,
    :d_major,
    :a_major,
    :e_major,
    :b_major,
    :f_sharp_major,
    :c_sharp_major,
    :g_sharp_major,
    :f_flat_major,
    :c_flat_major,
    :g_flat_major,
    :d_flat_major,
    :a_flat_major,
    :e_flat_major,
    :b_flat_major,
    :f_major
  ]

  minor_key_order = [
    "a",
    "e",
    "b",
    "f sharp",
    "c sharp",
    "g sharp",
    "d sharp",
    "a sharp",
    "e sharp",
    "d flat",
    "a flat",
    "e flat",
    "b flat",
    "f",
    "c",
    "g",
    "d "
  ]

  accidental_spacing = line_spacing
  clef_x_offset = staff_scale - 10
  key_start_offset = staff_scale * 2
  base_staff_width = 100.0

  format_label =
    fn key_name, letter_case ->
      key =
        key_name
        |> String.replace("_", " ")
        |> String.trim()
        |> String.downcase()

      letter =
        key
        |> String.first()
        |> case do
          nil -> ""
          l when letter_case == :upper -> String.upcase(l)
          l -> String.downcase(l)
        end

      accidental =
        cond do
          String.contains?(key, "double sharp") ->
            double_sharp

          String.contains?(key, "double flat") or String.contains?(key, "double_flat") ->
            double_flat

          String.contains?(key, "sharp") ->
            sharp

          String.contains?(key, "flat") ->
            flat

          true ->
            ""
        end

      {letter, accidental}
    end

  horizontal_offset =
    fn accidental, letter_case ->
      base = label_font_size * if letter_case == :lower, do: 0.48, else: 0.52

      cond do
        accidental == sharp -> base + label_font_size * 0.1
        accidental == flat -> base + label_font_size * 0.2
        true -> base
      end
    end

  vertical_offset =
    fn accidental ->
      cond do
        accidental == sharp -> -label_font_size * 0.08
        accidental == flat -> label_font_size * 0.5
        true -> 0.0
      end
    end

  draw_label =
    fn x, y, key_name, letter_case, color ->
      {letter, accidental} = format_label.(key_name, letter_case)
      text(label_font, x, y, letter, fill: color)

      if accidental != "" do
        text(
          music_font,
          x + horizontal_offset.(accidental, letter_case),
          y + vertical_offset.(accidental),
          accidental,
          fill: color
        )
      end
    end

  Enum.with_index(key_order)
  |> Enum.each(fn {key, idx} ->
    accidentals = Map.fetch!(keys, key)
    # Width scales with accidental count.
    staff_width = base_staff_width + accidental_spacing * max(length(accidentals) - 1, 0)
    half_w = staff_width / 2.0
    acc_count = length(accidentals)

    angle = idx * (:math.pi() * 2) / length(key_order) - :math.pi() / 2
    ring_radius = base_radius * 1.2 + acc_count
    staff_center_x = center_x + ring_radius * :math.cos(angle)
    staff_center_y = center_y + ring_radius * :math.sin(angle)
    # Rotate the entire key group about its own center.
    m =
      matrix do
        translate(staff_center_x, staff_center_y)
        rotate(angle + :math.pi() / 2)
      end

    with_transform m do
      staff_left = -half_w
      staff_right = half_w

      Enum.each(0..4, fn line_idx ->
        offset = (line_idx - 2) * line_spacing
        y = offset

        line(staff_left, y, staff_right, y, stroke: staff_color)
      end)

      # G clef.
      clef_x = staff_left + clef_x_offset
      clef_y = staff_scale

      text(music_font, clef_x, clef_y, <<0xE050::utf8>>, fill: clef_color)

      # Accidentals for this key.
      Enum.with_index(accidentals)
      |> Enum.each(fn {pitch, a_idx} ->
        y_steps = Map.fetch!(pitch_y_steps, pitch)
        pitch_name = Atom.to_string(pitch)

        glyph =
          cond do
            String.ends_with?(pitch_name, "double_flat") -> double_flat
            String.ends_with?(pitch_name, "double_sharp") -> double_sharp
            String.ends_with?(pitch_name, "sharp") -> sharp
            true -> flat
          end

        text(
          music_font,
          clef_x + key_start_offset + a_idx * accidental_spacing,
          -(y_steps * note_step),
          glyph,
          fill: accidental_color
        )
      end)

      # Labels anchored to the rotated group so they share orientation.
      major_key = Atom.to_string(key)
      minor_key = Enum.at(minor_key_order, idx)

      label_y = line_spacing * 4.5

      draw_label.(
        -half_w + 24,
        label_y - line_spacing * 9,
        major_key,
        :upper,
        major_label_color
      )

      draw_label.(
        -half_w + 34,
        label_y + line_spacing * 4.6,
        minor_key,
        :lower,
        minor_label_color
      )
    end
  end)
end
