defmodule BlendendPlaygroundPhx.Examples do
  @moduledoc """
  Helpers for listing and loading code examples from `priv/examples`.
  """

  @spec format(String.t(), String.t()) :: {:ok, String.t()} | {:error, atom() | String.t()}
  def format(name, code) when is_binary(name) and is_binary(code) do
    if name == "custom" or name in all() do
      path = Path.join(examples_dir(), name <> ".exs")

      formatted =
        try do
          code
          |> Code.format_string!(formatter_opts())
          |> IO.iodata_to_binary()
        rescue
          error in [SyntaxError, TokenMissingError] ->
            {:error, Exception.message(error)}
        end

      case formatted do
        {:error, reason} ->
          {:error, reason}

        formatted_code ->
          formatted_code = ensure_trailing_newline(formatted_code)

          case File.write(path, formatted_code) do
            :ok -> {:ok, formatted_code}
            {:error, reason} -> {:error, to_string(reason)}
          end
      end
    else
      {:error, :unknown_example}
    end
  end

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

  defp formatter_opts do
    with {:ok, path} <- find_formatter_file(File.cwd!()),
         {opts, _binding} <- Code.eval_file(path),
         true <- is_list(opts) do
      opts
    else
      _ -> []
    end
  rescue
    _ -> []
  end

  defp find_formatter_file(dir) do
    path = Path.join(dir, ".formatter.exs")

    cond do
      File.exists?(path) ->
        {:ok, path}

      Path.dirname(dir) == dir ->
        :error

      true ->
        find_formatter_file(Path.dirname(dir))
    end
  end

  defp ensure_trailing_newline(code) when is_binary(code) do
    if String.ends_with?(code, "\n"), do: code, else: code <> "\n"
  end
end
