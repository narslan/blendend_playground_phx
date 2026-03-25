defmodule BlendendPlaygroundPhx.Text.InlineLayout do
  alias Blendend.Text.{Font, GlyphBuffer, GlyphRun}

  defp draw_and_measure(text, font, x, y, c) do
    gb =
      GlyphBuffer.new!()
      |> GlyphBuffer.set_utf8_text!(text)
      |> Font.shape!(font)

    run = GlyphRun.new!(gb)

    GlyphRun.fill!(c, font, x, y, run)

    adv = Font.get_text_metrics!(font, gb)["advance_x"]

    {adv, run}
  end

  def layout_inline(tokens, font, base_x, base_y, opts \\ []) do
    c = Keyword.fetch!(opts, :canvas)

    metrics = Font.metrics!(font)
    IO.inspect(metrics)
    scale = Keyword.get(opts, :script_scale, 0.65)

    face = Keyword.get(opts, :face)
    font_sup = Font.create!(face, metrics["size"] * scale)

    sup_y = metrics["underline_position"] * 0.8
    sub_y = -metrics["underline_position"] * 0.3

    pen_x =
      Enum.reduce(tokens, {base_x, nil}, fn
        {:cluster, items}, {pen_x, last_x} ->
          Enum.each(items, fn
            {:sup, text} ->
              draw_and_measure(text, font_sup, last_x, base_y + sup_y, c)

            {:sub, text} ->
              draw_and_measure(text, font_sup, last_x, base_y + sub_y, c)
          end)

          # pen_x bleibt gleich!
          {pen_x, last_x}

        {:normal, text}, {pen_x, _last_x} ->
          {adv, _} = draw_and_measure(text, font, pen_x, base_y, c)
          {pen_x + adv, pen_x}
      end)

    pen_x
  end
end
