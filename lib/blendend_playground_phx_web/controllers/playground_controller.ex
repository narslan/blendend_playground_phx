defmodule BlendendPlaygroundPhxWeb.PlaygroundController do
  use BlendendPlaygroundPhxWeb, :controller

  def index(conn, _params) do
    render_index(conn, default_code(), false, nil, nil)
  end

  def submit(conn, %{"playground" => %{"code" => code}}) do
    {image_base64, error} = render_code(code)
    render_index(conn, code, true, image_base64, error)
  end

  def submit(conn, _params) do
    render_index(conn, default_code(), true, nil, "Missing code input.")
  end

  defp default_code do
    """
    draw 420, 240 do
      clear(fill: rgb(245, 245, 242))
      rect(40, 40, 160, 80, fill: rgb(58, 102, 152))
      text(load_font("priv/fonts/AlegreyaSans-Regular.otf", 18.0), 40, 160, "Hello Blendend")
    end
    """
  end

  defp render_index(conn, code, submitted?, image_base64, error) do
    form = Phoenix.Component.to_form(%{"code" => code}, as: :playground)

    render(conn, :index,
      form: form,
      submitted?: submitted?,
      image_base64: image_base64,
      error: error
    )
  end

  defp render_code(code) do
    case BlendendPlaygroundPhx.Renderer.render(code) do
      {:ok, base64} -> {base64, nil}
      {:error, reason} -> {nil, to_string(reason)}
    end
  end
end
