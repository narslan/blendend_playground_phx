defmodule BlendendPlaygroundPhxWeb.PlaygroundLive do
  use BlendendPlaygroundPhxWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    code = default_code()
    examples = BlendendPlaygroundPhx.Examples.all()
    example_options = build_example_options(examples)

    socket =
      socket
      |> assign(:form, to_form(%{"code" => code, "example" => "custom"}, as: :playground))
      |> assign(:submitted?, false)
      |> assign(:image_base64, nil)
      |> assign(:error, nil)
      |> assign(:examples, examples)
      |> assign(:example_options, example_options)
      |> assign(:code, code)
      |> assign(:example, "custom")

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
     |> assign(:form, to_form(%{"code" => code, "example" => "custom"}, as: :playground))
     |> assign(:submitted?, true)
     |> assign(:image_base64, image_base64)
     |> assign(:error, error)
     |> assign(:code, code)
     |> assign(:example, "custom")}
  end

  def handle_event("select-example", %{"playground" => %{"example" => name}}, socket) do
    {code, example} =
      if name == "custom" do
        {socket.assigns.code, "custom"}
      else
        {BlendendPlaygroundPhx.Examples.get(name) || socket.assigns.code, name}
      end

    {image_base64, error} = render_code(code)

    {:noreply,
     socket
     |> assign(:form, to_form(%{"code" => code, "example" => example}, as: :playground))
     |> assign(:submitted?, true)
     |> assign(:image_base64, image_base64)
     |> assign(:error, error)
     |> assign(:code, code)
     |> assign(:example, example)}
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

  defp build_example_options(examples) do
    [{"Custom", "custom"} | Enum.map(examples, &{humanize(&1), &1})]
  end

  defp humanize(name) do
    name
    |> String.replace("_", " ")
    |> String.replace("-", " ")
    |> String.split()
    |> Enum.map(&capitalize_segment/1)
    |> Enum.join(" ")
  end

  defp capitalize_segment(<<first::utf8, rest::binary>>) do
    String.upcase(<<first::utf8>>) <> rest
  end

  defp capitalize_segment(segment), do: segment
end
