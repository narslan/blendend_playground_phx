defmodule BlendendPlaygroundPhx.Gradients do
  @moduledoc """
  Helpers for constructing gradients for demos.

  These are intended for `priv/examples/*.exs` where it can be tedious and
  error-prone to hand-write stop loops.
  """

  alias Blendend.Style.Gradient

  @type box :: {number(), number(), number(), number()}
  @type line :: {number(), number(), number(), number()}
  @type direction :: :horizontal | :vertical | :diagonal

  @doc """
  Builds a linear gradient by sampling a `Scale` over `t=0..1`.

  Options:

    * `:steps` - number of segments (default: `10`). Generates `steps + 1` stops.
    * `:direction` - `:horizontal | :vertical | :diagonal` (default: `:horizontal`).
    * `:line` - explicit gradient line `{x0, y0, x1, y1}` (overrides `:direction`).
    * `:map` - function to convert `Scale.map/2` output into a Blendend color
      resource (default: `&Blendend.Draw.rgb/1`).
    * `:extend` - gradient extend mode (`:pad | :repeat | :reflect`) (default: `:pad`).
  """
  @spec linear_from_scale(box(), term(), keyword()) :: Gradient.t()
  def linear_from_scale({x0, y0, x1, y1}, scale, opts \\ []) do
    steps = Keyword.get(opts, :steps, 10)
    extend = Keyword.get(opts, :extend, :pad)
    map_color = Keyword.get(opts, :map, &Blendend.Draw.rgb/1)

    if not (is_integer(steps) and steps >= 1) do
      raise ArgumentError, ":steps must be an integer >= 1, got: #{inspect(steps)}"
    end

    {gx0, gy0, gx1, gy1} =
      case Keyword.get(opts, :line) do
        {a0, b0, a1, b1} ->
          {a0, b0, a1, b1}

        nil ->
          case Keyword.get(opts, :direction, :horizontal) do
            :horizontal -> {x0, y0, x1, y0}
            :vertical -> {x0, y0, x0, y1}
            :diagonal -> {x0, y0, x1, y1}
            other -> raise ArgumentError, "invalid :direction: #{inspect(other)}"
          end
      end

    grad = Gradient.linear!(gx0, gy0, gx1, gy1) |> Gradient.set_extend!(extend)

    Enum.each(0..steps, fn i ->
      t = i / steps
      Gradient.add_stop!(grad, t, map_color.(Scale.map(scale, t)))
    end)

    grad
  end

  @doc """
  Convenience: builds a gradient with `linear_from_scale/3` and fills the given box with it.

  Returns the created gradient.
  """
  @spec linear_box_from_scale(box(), term(), keyword()) :: Gradient.t()
  def linear_box_from_scale({x0, y0, x1, y1} = box, scale, opts \\ []) do
    grad = linear_from_scale(box, scale, opts)
    :ok = Blendend.Draw.box(x0, y0, x1, y1, fill: grad)
    grad
  end

  @doc """
  Like `linear_box_from_scale/3`, but also draws a label on top of the box.

  Options:

    * `:label_font` - required, a `Blendend.Text.Font` resource.
    * `:label_fill` - label color (default: black).
    * `:label_bg_fill` - background color behind label (default: translucent white).
    * `:label_bg` - set to `false` to disable the label background.
    * `:label_padding` - `{px, py}` padding inside the box (default: `{8.0, 18.0}` baseline).
    * `:label_bg_size` - `{w, h}` background rect size (default: `{240.0, 22.0}`).
  """
  @spec linear_labeled_box_from_scale(box(), term(), iodata(), keyword()) :: Gradient.t()
  def linear_labeled_box_from_scale({x0, y0, _x1, _y1} = box, scale, label, opts \\ []) do
    grad = linear_box_from_scale(box, scale, opts)

    font =
      Keyword.get(opts, :label_font) ||
        raise ArgumentError, ":label_font is required to draw labels"

    label_fill = Keyword.get(opts, :label_fill, Blendend.Draw.rgb(0, 0, 0, 230))
    label_bg? = Keyword.get(opts, :label_bg, true)
    label_bg_fill = Keyword.get(opts, :label_bg_fill, Blendend.Draw.rgb(255, 255, 255, 190))
    {pad_x, pad_y} = Keyword.get(opts, :label_padding, {8.0, 18.0})
    {bg_w, bg_h} = Keyword.get(opts, :label_bg_size, {240.0, 22.0})

    if label_bg? do
      Blendend.Draw.rect(x0 + pad_x - 4.0, y0 + 4.0, bg_w, bg_h, fill: label_bg_fill)
    end

    Blendend.Draw.text(font, x0 + pad_x, y0 + pad_y, IO.iodata_to_binary(label), fill: label_fill)

    grad
  end
end
