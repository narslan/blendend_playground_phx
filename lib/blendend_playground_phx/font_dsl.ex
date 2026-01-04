defmodule BlendendPlaygroundPhx.FontDSL do
  @moduledoc """
  Small DSL for requesting fonts from `BlendendPlaygroundPhx.Fonts` (ETS-backed).

  Intended for the code snippets evaluated by `BlendendPlaygroundPhx.Renderer`,
  so examples under `priv/examples` can write `font("AlegreyaSans", 30.0)` instead
  of hardcoding filesystem paths.
  """

  alias BlendendPlaygroundPhx.Fonts

  defmacro font(id, size) do
    quote do
      path = BlendendPlaygroundPhx.FontDSL.__font_path__(unquote(id), nil)
      load_font(path, unquote(size))
    end
  end

  defmacro font(id, size, style) do
    quote do
      path = BlendendPlaygroundPhx.FontDSL.__font_path__(unquote(id), unquote(style))
      load_font(path, unquote(size))
    end
  end

  defmacro font_face(face_id, size) do
    quote do
      path = BlendendPlaygroundPhx.FontDSL.__face_path__(unquote(face_id))
      load_font(path, unquote(size))
    end
  end

  @doc false
  def __font_path__(id, style) do
    id = normalize_identifier(id)
    style = normalize_style(style)

    case Fonts.lookup(id, style) do
      {:ok, %{absolute_path: path}} when is_binary(path) ->
        path

      _ ->
        raise ArgumentError,
              "unknown font family #{inspect(id)} (style: #{inspect(style)}); " <>
                "open /fonts to see available families"
    end
  end

  @doc false
  def __face_path__(face_id) do
    face_id = normalize_identifier(face_id)

    case Fonts.face(face_id) do
      {:ok, %{absolute_path: path}} when is_binary(path) ->
        path

      _ ->
        raise ArgumentError,
              "unknown font face #{inspect(face_id)}; open /fonts to see available faces"
    end
  end

  defp normalize_identifier(id) when is_atom(id), do: Atom.to_string(id)
  defp normalize_identifier(id) when is_binary(id), do: String.trim(id)
  defp normalize_identifier(other), do: to_string(other)

  defp normalize_style(nil), do: nil
  defp normalize_style(style) when is_atom(style), do: Atom.to_string(style)
  defp normalize_style(style) when is_binary(style), do: style |> String.trim() |> empty_as_nil()
  defp normalize_style(style), do: style |> to_string() |> String.trim() |> empty_as_nil()

  defp empty_as_nil(""), do: nil
  defp empty_as_nil(value), do: value
end
