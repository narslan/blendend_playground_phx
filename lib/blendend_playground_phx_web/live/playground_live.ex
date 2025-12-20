defmodule BlendendPlaygroundPhxWeb.PlaygroundLive do
  use BlendendPlaygroundPhxWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    code = default_code()

    socket =
      socket
      |> assign(:form, to_form(%{"code" => code}, as: :playground))
      |> assign(:submitted?, false)
      |> assign(:image_base64, nil)
      |> assign(:error, nil)

    if connected?(socket) do
      send(self(), {:render_code, code})
    end

    {:ok, socket}
  end

  @impl true
  def handle_event("code-change", %{"playground" => %{"code" => code}}, socket) do
    {image_base64, error} = render_code(code)

    {:noreply,
     socket
     |> assign(:form, to_form(%{"code" => code}, as: :playground))
     |> assign(:submitted?, true)
     |> assign(:image_base64, image_base64)
     |> assign(:error, error)}
  end

  @impl true
  def handle_info({:render_code, code}, socket) do
    {image_base64, error} = render_code(code)

    {:noreply,
     socket
     |> assign(:submitted?, true)
     |> assign(:image_base64, image_base64)
     |> assign(:error, error)}
  end

  defp render_code(code) do
    case BlendendPlaygroundPhx.Renderer.render(code) do
      {:ok, base64} -> {base64, nil}
      {:error, reason} -> {nil, to_string(reason)}
    end
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
end
