defmodule BlendendPlaygroundPhx.Text.InlineLayout do
  @moduledoc """
  Shapes and draws inline text with manual subscript and superscript clusters.

  The layout is intentionally simple: every normal token advances the pen by its
  shaped width, while a script cluster paints its sub/sup runs at the same
  horizontal anchor and advances by the widest script run.
  """

  alias Blendend.Text.{Font, GlyphBuffer, GlyphRun}

  @default_script_scale 0.65
  @default_superscript_rise_factor 0.35
  @default_subscript_drop_factor 0.18
  @default_cluster_gap 0.0

  @type token ::
          {:text | :normal, String.t()}
          | {:cluster, [script_item()]}
          | {:script, keyword(String.t())}

  @type script_item :: {:sup | :sub, String.t()}

  @spec layout_inline([token()], term(), number(), number(), keyword()) :: float()
  def layout_inline(tokens, font, base_x, base_y, opts \\ []) when is_list(tokens) do
    canvas = Keyword.fetch!(opts, :canvas)
    fill = Keyword.get(opts, :fill)
    base_metrics = Font.metrics!(font)

    script_font =
      Keyword.get_lazy(opts, :script_font, fn ->
        face =
          Keyword.get(opts, :face) ||
            raise ArgumentError,
                  "expected :face or :script_font when laying out subscript/superscript text"

        Font.create!(
          face,
          base_metrics["size"] * Keyword.get(opts, :script_scale, @default_script_scale)
        )
      end)

    state = %{
      base_y: base_y,
      canvas: canvas,
      cluster_gap: Keyword.get(opts, :cluster_gap, @default_cluster_gap),
      fill: fill,
      font: font,
      script_font: script_font,
      subscript_y:
        base_y +
          Keyword.get(
            opts,
            :subscript_drop,
            base_metrics["size"] * @default_subscript_drop_factor
          ),
      superscript_y:
        base_y -
          Keyword.get(
            opts,
            :superscript_rise,
            base_metrics["size"] * @default_superscript_rise_factor
          )
    }

    Enum.reduce(tokens, base_x * 1.0, fn token, pen_x ->
      pen_x + advance_token(token, pen_x, state)
    end)
  end

  defp advance_token({kind, text}, pen_x, %{font: font} = state) when kind in [:text, :normal] do
    draw_segment(text, font, pen_x, state.base_y, state)
  end

  defp advance_token({:cluster, items}, pen_x, state) when is_list(items) do
    draw_cluster(items, pen_x, state)
  end

  defp advance_token({:script, items}, pen_x, state) when is_list(items) do
    items
    |> normalize_script_items()
    |> draw_cluster(pen_x, state)
  end

  defp advance_token(other, _pen_x, _state) do
    raise ArgumentError, "unsupported inline layout token: #{inspect(other)}"
  end

  defp draw_cluster(items, pen_x, state) do
    advances =
      Enum.map(items, fn
        {:sup, text} ->
          draw_segment(text, state.script_font, pen_x, state.superscript_y, state)

        {:sub, text} ->
          draw_segment(text, state.script_font, pen_x, state.subscript_y, state)

        other ->
          raise ArgumentError, "unsupported script item: #{inspect(other)}"
      end)

    Enum.max([0.0 | advances]) + state.cluster_gap
  end

  defp draw_segment(text, font, x, y, state) when is_binary(text) do
    buffer =
      GlyphBuffer.new!()
      |> GlyphBuffer.set_utf8_text!(text)
      |> Font.shape!(font)

    run = GlyphRun.new!(buffer)
    draw_opts = maybe_fill(state.fill)
    GlyphRun.fill!(state.canvas, font, x, y, run, draw_opts)
    Font.get_text_metrics!(font, buffer)["advance_x"]
  end

  defp normalize_script_items(items) do
    Enum.map(items, fn
      {:sup, text} when is_binary(text) ->
        {:sup, text}

      {:sub, text} when is_binary(text) ->
        {:sub, text}

      {kind, nil} when kind in [:sup, :sub] ->
        {kind, ""}

      other ->
        raise ArgumentError, "unsupported script cluster: #{inspect(other)}"
    end)
  end

  defp maybe_fill(nil), do: []
  defp maybe_fill(fill), do: [fill: fill]
end
