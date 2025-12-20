defmodule BlendendPlaygroundPhx.Renderer do
  @moduledoc """
  Evaluates Blendend.Draw code and returns base64-encoded PNG output.
  """

  @spec render(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def render(code) when is_binary(code) do
    header = """
    use Blendend.Draw
    #{code}
    """

    try do
      {result, _binding} = Code.eval_string(header, [], file: "playground.exs")

      case result do
        {:ok, base64} when is_binary(base64) ->
          {:ok, base64}

        other ->
          {:error, "unexpected result: #{inspect(other)}"}
      end
    rescue
      e -> {:error, Exception.message(e)}
    end
  end
end
