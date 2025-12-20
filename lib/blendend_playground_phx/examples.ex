defmodule BlendendPlaygroundPhx.Examples do
  @moduledoc """
  Helpers for listing and loading code examples from `priv/examples`.
  """

  @spec all() :: [String.t()]
  def all do
    examples_dir()
    |> File.ls()
    |> case do
      {:ok, files} ->
        files
        |> Enum.filter(&String.ends_with?(&1, ".exs"))
        |> Enum.map(&String.trim_trailing(&1, ".exs"))
        |> Enum.sort()

      {:error, _} ->
        []
    end
  end

  @spec get(String.t()) :: String.t() | nil
  def get(name) when is_binary(name) do
    path = Path.join(examples_dir(), name <> ".exs")
    if File.exists?(path), do: File.read!(path), else: nil
  end

  defp examples_dir do
    :blendend_playground_phx
    |> :code.priv_dir()
    |> to_string()
    |> Path.join("examples")
  end
end
