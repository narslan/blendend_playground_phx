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

  @spec save(String.t(), String.t()) :: :ok | {:error, atom()}
  def save(name, code) when is_binary(name) and is_binary(code) do
    if name == "custom" or name in all() do
      path = Path.join(examples_dir(), name <> ".exs")
      File.write(path, code)
    else
      {:error, :unknown_example}
    end
  end

  @spec save_new(String.t(), String.t()) :: {:ok, String.t()} | {:error, atom()}
  def save_new(name, code) when is_binary(name) and is_binary(code) do
    with {:ok, normalized} <- normalize_name(name),
         false <- normalized == "custom" or normalized in all() do
      path = Path.join(examples_dir(), normalized <> ".exs")

      case File.write(path, code) do
        :ok -> {:ok, normalized}
        {:error, reason} -> {:error, reason}
      end
    else
      true -> {:error, :already_exists}
      {:error, reason} -> {:error, reason}
    end
  end

  defp normalize_name(name) do
    normalized =
      name
      |> String.trim()
      |> String.downcase()
      |> String.trim_trailing(".exs")
      |> String.replace(~r/\s+/, "_")

    if normalized == "" do
      {:error, :invalid_name}
    else
      case Regex.match?(~r/^[a-z0-9][a-z0-9_-]*$/, normalized) do
        true -> {:ok, normalized}
        false -> {:error, :invalid_name}
      end
    end
  end

  defp examples_dir do
    :blendend_playground_phx
    |> :code.priv_dir()
    |> to_string()
    |> Path.join("examples")
  end
end
