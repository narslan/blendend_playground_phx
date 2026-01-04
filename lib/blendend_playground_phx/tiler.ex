defmodule BlendendPlaygroundPhx.Tiler do
  @moduledoc """
  Helpers for laying out tabular data (grids/tables) in 2D.

  The core idea is a pair of `Scale.Band` scales (rows + columns) that map
  row/column keys into pixel coordinates and expose a cell rectangle for each
  `{row, col}` address.

  This is intentionally render-agnostic: you get rectangles; you decide how to
  draw them.
  """

  alias __MODULE__

  @type key :: term()

  @enforce_keys [:rows, :cols, :x_scale, :y_scale, :cell_w, :cell_h, :rect]
  defstruct [:rows, :cols, :x_scale, :y_scale, :cell_w, :cell_h, :rect, :data]

  @type rect :: %{
          required(:x) => number(),
          required(:y) => number(),
          required(:w) => number(),
          required(:h) => number(),
          required(:x1) => number(),
          required(:y1) => number(),
          required(:cx) => number(),
          required(:cy) => number()
        }

  @doc """
  Create a band-based tiler from explicit row/col keys and a table rectangle.

  Options:
    - `:padding_inner` (default: 0.0) - applied to both axes
    - `:padding_outer` (default: 0.0) - applied to both axes
    - `:x_padding_inner`/`:x_padding_outer`, `:y_padding_inner`/`:y_padding_outer` - axis-specific
  """
  @spec new(rows :: [key()], cols :: [key()], rect_input(), keyword()) :: t()
  def new(rows, cols, rect, opts \\ []) when is_list(rows) and is_list(cols) and is_list(opts) do
    rect = normalize_rect!(rect)

    padding_inner = Keyword.get(opts, :padding_inner, 0.0)
    padding_outer = Keyword.get(opts, :padding_outer, 0.0)

    x_padding_inner = Keyword.get(opts, :x_padding_inner, padding_inner)
    x_padding_outer = Keyword.get(opts, :x_padding_outer, padding_outer)
    y_padding_inner = Keyword.get(opts, :y_padding_inner, padding_inner)
    y_padding_outer = Keyword.get(opts, :y_padding_outer, padding_outer)

    x_scale =
      Scale.Band.new(
        domain: cols,
        range: [rect.x, rect.x + rect.w],
        padding_inner: x_padding_inner,
        padding_outer: x_padding_outer
      )

    y_scale =
      Scale.Band.new(
        domain: rows,
        range: [rect.y, rect.y + rect.h],
        padding_inner: y_padding_inner,
        padding_outer: y_padding_outer
      )

    %Tiler{
      rows: rows,
      cols: cols,
      x_scale: x_scale,
      y_scale: y_scale,
      cell_w: Scale.Band.bandwidth(x_scale),
      cell_h: Scale.Band.bandwidth(y_scale),
      rect: rect
    }
  end

  @doc """
  Create a simple grid tiler with integer row/column indices.
  """
  @spec grid(non_neg_integer(), non_neg_integer(), rect_input(), keyword()) :: t()
  def grid(row_count, col_count, rect, opts \\ [])
      when is_integer(row_count) and row_count >= 0 and is_integer(col_count) and col_count >= 0 do
    rows = Enum.to_list(0..max(row_count - 1, 0)) |> Enum.take(row_count)
    cols = Enum.to_list(0..max(col_count - 1, 0)) |> Enum.take(col_count)
    new(rows, cols, rect, opts)
  end

  @doc """
  Create a tiler for a matrix (list of rows). Rows/cols are 0-based indices.
  Stores the original data in the tiler for convenience via `value/4`.
  """
  @spec table([[term()]], rect_input(), keyword()) :: t()
  def table(data, rect, opts \\ []) when is_list(data) do
    row_count = length(data)

    col_count =
      data
      |> Enum.map(fn row -> if is_list(row), do: length(row), else: 0 end)
      |> Enum.max(fn -> 0 end)

    tiler = grid(row_count, col_count, rect, opts)
    %{tiler | data: data}
  end

  @doc """
  Return the pixel rect for a given `{row_key, col_key}`.
  """
  @spec cell(t(), key(), key()) :: {:ok, rect()} | {:error, :unknown_cell}
  def cell(%Tiler{} = tiler, row, col) do
    with x when is_number(x) <- Scale.map(tiler.x_scale, col),
         y when is_number(y) <- Scale.map(tiler.y_scale, row) do
      w = tiler.cell_w
      h = tiler.cell_h

      {:ok,
       %{
         x: x,
         y: y,
         w: w,
         h: h,
         x1: x + w,
         y1: y + h,
         cx: x + w / 2,
         cy: y + h / 2
       }}
    else
      _ -> {:error, :unknown_cell}
    end
  end

  @doc """
  Same as `cell/3`, but raises when the address is invalid.
  """
  @spec cell!(t(), key(), key()) :: rect()
  def cell!(%Tiler{} = tiler, row, col) do
    case cell(tiler, row, col) do
      {:ok, rect} -> rect
      {:error, :unknown_cell} -> raise ArgumentError, "unknown cell: #{inspect({row, col})}"
    end
  end

  @doc """
  Get a value from a matrix-backed tiler.
  """
  @spec value(t(), non_neg_integer(), non_neg_integer(), term()) :: term()
  def value(%Tiler{data: data}, row, col, default \\ nil)
      when is_integer(row) and row >= 0 and is_integer(col) and col >= 0 do
    case data do
      rows when is_list(rows) ->
        row_list = Enum.at(rows, row)

        if is_list(row_list) do
          Enum.at(row_list, col, default)
        else
          default
        end

      _ ->
        default
    end
  end

  @doc """
  Inset a rect by padding (number or `{x_pad, y_pad}`).
  """
  @spec inset(rect(), number() | {number(), number()}) :: rect()
  def inset(%{x: x, y: y, w: w, h: h}, pad) when is_number(pad) do
    inset(%{x: x, y: y, w: w, h: h}, {pad, pad})
  end

  def inset(%{x: x, y: y, w: w, h: h}, {pad_x, pad_y})
      when is_number(pad_x) and is_number(pad_y) do
    x = x + pad_x
    y = y + pad_y
    w = max(w - pad_x * 2, 0)
    h = max(h - pad_y * 2, 0)

    %{
      x: x,
      y: y,
      w: w,
      h: h,
      x1: x + w,
      y1: y + h,
      cx: x + w / 2,
      cy: y + h / 2
    }
  end

  @type rect_input ::
          {number(), number(), number(), number()}
          | %{x: number(), y: number(), w: number(), h: number()}

  @type t :: %Tiler{
          rows: [key()],
          cols: [key()],
          x_scale: term(),
          y_scale: term(),
          cell_w: number(),
          cell_h: number(),
          rect: %{x: number(), y: number(), w: number(), h: number()},
          data: [[term()]] | nil
        }

  defp normalize_rect!({x, y, w, h})
       when is_number(x) and is_number(y) and is_number(w) and is_number(h) do
    %{x: x * 1.0, y: y * 1.0, w: w * 1.0, h: h * 1.0}
  end

  defp normalize_rect!(%{x: x, y: y, w: w, h: h})
       when is_number(x) and is_number(y) and is_number(w) and is_number(h) do
    %{x: x * 1.0, y: y * 1.0, w: w * 1.0, h: h * 1.0}
  end

  defp normalize_rect!(other) do
    raise ArgumentError,
          "expected rect as {x, y, w, h} or %{x:, y:, w:, h:}, got: #{inspect(other)}"
  end
end
