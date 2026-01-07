defmodule BlendendPlaygroundPhx.Renderer do
  @moduledoc """
  Evaluates Blendend.Draw code and returns base64-encoded PNG output.
  """

  @spec render(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def render(code) when is_binary(code) do
    header = """
    use Blendend.Draw
    import BlendendPlaygroundPhx.FontDSL
    import BlendendPlaygroundPhx.PaletteDSL
    #{code}
    """

    try do
      {result, _binding} = Code.eval_string(header, [], file: "playground.exs")

      case result do
        {:ok, base64} when is_binary(base64) ->
          {:ok, base64}

        {:error, reason} ->
          {:error, format_reason(reason)}

        other ->
          {:error, "unexpected result: #{inspect(other)}"}
      end
    rescue
      e -> {:error, format_failure(:error, e, __STACKTRACE__)}
    catch
      kind, reason -> {:error, format_failure(kind, reason, __STACKTRACE__)}
    end
  end

  defp format_reason(reason) when is_binary(reason) do
    reason = String.trim(reason)
    if reason == "", do: "Unknown error", else: reason
  end

  defp format_reason(reason), do: inspect(reason)

  defp format_failure(kind, reason, stacktrace) do
    formatted =
      kind
      |> Exception.format(reason, stacktrace)
      |> String.trim()

    if formatted == "", do: inspect({kind, reason}), else: formatted
  end
end
