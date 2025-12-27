defmodule BlendendPlaygroundPhx.RgbPicker do
  @moduledoc """
  Renders a simple RGB picker plane (R across X, G across Y, fixed B) using Blendend.
  """

  use Blendend.Draw

  @spec render_rg_plane(non_neg_integer() | binary(), pos_integer()) ::
          {:ok, String.t()} | {:error, String.t()}
  def render_rg_plane(b \\ 128, size \\ 256) do
    b = clamp_0_255(b)
    size = clamp_size(size)

    try do
      draw size, size do
        Enum.each(0..(size - 1), fn y ->
          g = round(y * 255 / max(size - 1, 1))

          grad =
            linear_gradient 0, 0, size, 0 do
              add_stop(0.0, rgb(0, g, b))
              add_stop(1.0, rgb(255, g, b))
            end

          rect(0, y, size, 1, fill: grad)
        end)
      end
    rescue
      e -> {:error, Exception.message(e)}
    catch
      :exit, reason -> {:error, inspect(reason)}
      kind, reason -> {:error, "#{inspect(kind)}: #{inspect(reason)}"}
    end
  end

  defp clamp_0_255(val) when is_integer(val), do: min(max(val, 0), 255)

  defp clamp_0_255(val) when is_binary(val) do
    case Integer.parse(val) do
      {int, _} -> clamp_0_255(int)
      :error -> 128
    end
  end

  defp clamp_0_255(_), do: 128

  defp clamp_size(val) when is_integer(val), do: min(max(val, 32), 512)
  defp clamp_size(_), do: 256
end
