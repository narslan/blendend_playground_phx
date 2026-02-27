defmodule DebugLayout do
  use Blendend.Draw

  def log_font_metrics(fm, font_debug_metrics) do
    Enum.reduce(fm, 0, fn {k, v}, acc ->
      formatted = format_value(v)
      text(font_debug_metrics, 610, 520 + acc, "#{k} #{formatted}", fill: hsv(5, 0.5, 0.55))
      acc + 40
    end)
  end

  def log_text_metrics(tm, font_debug_metrics) do
    Enum.reduce(tm, 0, fn {k, v}, acc ->
      formatted = format_value(v)
      text(font_debug_metrics, 10, 520 + acc, "#{k} #{formatted}", fill: hsv(5, 0.5, 0.55))
      acc + 40
    end)
  end

  defp format_value(v) when is_float(v),
    do: :erlang.float_to_binary(v, decimals: 2)

  defp format_value(v),
    do: to_string(v)
end

defmodule MultilineLayout do
  use Blendend.Draw
  alias Blendend.Text.{Font, GlyphBuffer, GlyphRun}

  def schreib(canvas, font, fm, text) do
    lines = String.split(text, "\n", trim: true)
    num_lines = length(lines)
    {width, height} = {1500, 1500}
    {w, h} = {width, height * 0.2}

    start_y = (h - num_lines * fm["size"] + fm["ascent"]) / 2.0

    line_height = fm["ascent"] + fm["descent"] + fm["line_gap"]

    fill_style = hsv(0, 0.75, 0.95)

    Enum.reduce(lines, start_y, fn line, y ->
      gb =
        GlyphBuffer.new!()
        |> GlyphBuffer.set_utf8_text!(line)
        |> Font.shape!(font)

      gr = Blendend.Text.GlyphRun.new!(gb)

      tm = Font.get_text_metrics!(font, gb)
      DebugLayout.log_text_metrics(tm, font)
      x = (w - (tm["bbox_x1"] - tm["bbox_x0"])) / 2.0

      GlyphRun.fill!(canvas, font, x, y, gr, fill: fill_style)

      y + line_height
    end)
  end
end

defmodule TextBoundLayout do
  # Shows how to pull design-space bounding boxes via Font.glyph_bounds!/2.
  # Transforms them into user space and visualizes per-glyph extents next to the shaped run.
  use Blendend.Draw

  alias Blendend.Text.{Font, GlyphBuffer, GlyphRun}

  def inspect(font, font_small, text, base_x, base_y, color) do
    run =
      GlyphBuffer.new!()
      |> GlyphBuffer.set_utf8_text!(text)
      |> Font.shape!(font)
      |> GlyphRun.new!()

    glyphs = GlyphRun.inspect_run!(run)

    ids =
      for {:glyph, gid, _} <- glyphs do
        gid
      end

    # Design-space bounding boxes for each gid: {x0_d, y0_d, x1_d, y1_d}
    boxes_d = Font.glyph_bounds!(font, ids)

    # Font matrix: design -> user
    m = Font.matrix!(font)

    to_user = fn {xd, yd} ->
      {
        m["m00"] * xd + m["m01"] * yd,
        m["m10"] * xd + m["m11"] * yd
      }
    end

    # Convert each (glyph, box_d) into a *user-space* box, using advances
    boxes_u =
      Enum.zip(glyphs, boxes_d)
      |> Enum.map_reduce({0.0, 0.0}, fn
        {{:glyph, _gid, {:advance_offset, {ax, ay}, {px, py}}}, {x0_d, y0_d, x1_d, y1_d}},
        {pen_x, pen_y} ->
          # design-space origin of this glyph in the run
          origin_x = pen_x + px
          origin_y = pen_y + py

          # transform box corners to user space
          {ux0, uy0} = to_user.({origin_x + x0_d, origin_y + y0_d})
          {ux1, uy1} = to_user.({origin_x + x1_d, origin_y + y1_d})

          box_u = {ux0, uy0, ux1, uy1}
          new_pen = {pen_x + ax, pen_y + ay}

          {box_u, new_pen}
      end)
      |> elem(0)

    c = Blendend.Draw.get_canvas()

    # Draw the word
    GlyphRun.fill!(c, font, base_x, base_y, run, fill: rgb(230, 230, 230))

    # Draw each glyph's box (now aligned per glyph)
    boxes_u
    |> Enum.each(fn {ux0, uy0, ux1, uy1} ->
      x0 = base_x + ux0
      y0 = base_y + uy0
      x1 = base_x + ux1
      y1 = base_y + uy1

      box(
        x0,
        y0,
        x1,
        y1,
        stroke: Blendend.Style.Color.random(),
        stroke_width: 1.5
      )

      circle(x0, y0, 5.0, fill: hsv(0, 0.1, 1))
      circle(x0, y1, 5.0, fill: hsv(0, 0.1, 1))
      circle(x1, y1, 5.0, fill: hsv(160, 0.6, 0.5))
      circle(x1, y0, 5.0, fill: hsv(0, 0.6, 0.5))

      text(
        font_small,
        x0,
        y0 + 50,
        "#{format_value(x0)} #{format_value(y0)}",
        fill: color
      )

      text(
        font_small,
        x0,
        y0 + 150,
        "#{format_value(x1)} #{format_value(y1)}",
        fill: color
      )
    end)
  end

  defp format_value(v) when is_float(v),
    do: :erlang.float_to_binary(v, decimals: 2)

  defp format_value(v),
    do: to_string(v)
end
