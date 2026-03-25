defmodule BlendendPlayground.Text.InlineLayout do
  alias Blendend.Text.{Font, GlyphBuffer, GlyphRun}

  defp draw_and_measure(text, font, x, y, c) do
    gb =
      GlyphBuffer.new!()
      |> GlyphBuffer.set_utf8_text!(text)
      |> Font.shape!(font)

    run = GlyphRun.new!(gb)

    GlyphRun.fill!(c, font, x, y, run)

    adv = Font.get_text_metrics!(font, gb)["advance_x"]
        IO.inspect(adv)

    {adv, run}
  end

  def layout_inline(tokens, font, base_x, base_y, opts \\ []) do
    c = Keyword.fetch!(opts, :canvas)

    metrics = Font.metrics!(font)
    scale = Keyword.get(opts, :script_scale, 0.65)

    face = Keyword.get(opts, :face)
    font_sup = Font.create!(face, metrics["size"] * scale)

    sup_y = metrics["ascent"] * 0.8
    sub_y = metrics["y_min"] * 0.3

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
        {:normal, text}, {pen_x, nil} ->
    
          {adv, _} = draw_and_measure(text, font, 0, base_y, c)
          {pen_x + adv, pen_x}

        {:normal, text}, {pen_x, last_x} ->
    
          {adv, _} = draw_and_measure(text, font, last_x, base_y, c)
          {pen_x + adv, pen_x}
      end)

    pen_x
  end
end


alias Blendend.Text.{Face, Font, GlyphBuffer, GlyphRun}
# A4 Size
width = 800
height = 800

draw width, height do
  face = Face.load!("priv/fonts/Alegreya-Regular.otf")
  font = Font.create!(face, 60)

  tokens = [
    {:normal, "C"},
    {:normal, "H"},
    {:cluster,
     [
       {:sup, "+"},
       {:sub, "3"}
     ]}
  ]

  c = Blendend.Draw.get_canvas()

  BlendendPlayground.Text.InlineLayout.layout_inline(
    tokens,
    font,
    100,
    100,
    canvas: c,
    face: face
  )
end
