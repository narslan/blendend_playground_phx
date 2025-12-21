defmodule BlendendPlaygroundPhxWeb.PlaygroundLive do
  use BlendendPlaygroundPhxWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    custom_code = BlendendPlaygroundPhx.Examples.get("custom") || default_code()
    code = custom_code
    examples = BlendendPlaygroundPhx.Examples.all()
    example_options = build_example_options(examples)

    socket =
      socket
      |> assign(:form, to_form(%{"code" => code, "example" => "custom"}, as: :playground))
      |> assign(:save_form, to_form(%{"name" => ""}, as: :save))
      |> assign(:submitted?, false)
      |> assign(:image_base64, nil)
      |> assign(:error, nil)
      |> assign(:render_ms, nil)
      |> assign(:examples, examples)
      |> assign(:example_options, example_options)
      |> assign(:code, code)
      |> assign(:custom_code, custom_code)
      |> assign(:example, "custom")

    if connected?(socket) do
      send(self(), {:render_code, code})
    end

    {:ok, socket}
  end

  @impl true
  def handle_event("code-change", %{"playground" => %{"code" => code}}, socket) do
    example = socket.assigns.example
    {image_base64, error, render_ms} = render_code(code)

    {:noreply,
     socket
     |> assign(:form, to_form(%{"code" => code, "example" => example}, as: :playground))
     |> assign(:submitted?, true)
     |> assign(:image_base64, image_base64)
     |> assign(:error, error)
     |> assign(:render_ms, render_ms)
     |> assign(:code, code)
     |> assign(:example, example)
     |> maybe_assign_custom_code(example, code)}
  end

  @impl true
  def handle_event("save-code", %{"playground" => %{"code" => code}}, socket) do
    example = socket.assigns.example

    socket =
      socket
      |> assign(:form, to_form(%{"code" => code, "example" => example}, as: :playground))
      |> assign(:code, code)
      |> maybe_assign_custom_code(example, code)

    case BlendendPlaygroundPhx.Examples.save(example, code) do
      :ok ->
        {:noreply, put_flash(socket, :info, "Updated #{example}.exs")}

      {:error, :unknown_example} ->
        {:noreply, put_flash(socket, :error, "Unknown example selected.")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Unable to save: #{to_string(reason)}")}
    end
  end

  @impl true
  def handle_event("save-as", %{"save" => %{"name" => name}}, socket) do
    save_form = to_form(%{"name" => name}, as: :save)

    case BlendendPlaygroundPhx.Examples.save_new(name, socket.assigns.code) do
      {:ok, saved_name} ->
        examples = BlendendPlaygroundPhx.Examples.all()
        example_options = build_example_options(examples)
        code = socket.assigns.code
        {image_base64, error, render_ms} = render_code(code)

        {:noreply,
         socket
         |> assign(:examples, examples)
         |> assign(:example_options, example_options)
         |> assign(:form, to_form(%{"code" => code, "example" => saved_name}, as: :playground))
         |> assign(:example, saved_name)
         |> assign(:save_form, to_form(%{"name" => ""}, as: :save))
         |> assign(:submitted?, true)
         |> assign(:image_base64, image_base64)
         |> assign(:error, error)
         |> assign(:render_ms, render_ms)
         |> put_flash(:info, "Saved as #{saved_name}.exs")}

      {:error, :invalid_name} ->
        {:noreply,
         socket
         |> assign(:save_form, save_form)
         |> put_flash(:error, "Use letters, numbers, dashes, or underscores.")}

      {:error, :already_exists} ->
        {:noreply,
         socket
         |> assign(:save_form, save_form)
         |> put_flash(:error, "That example already exists.")}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:save_form, save_form)
         |> put_flash(:error, "Unable to save: #{to_string(reason)}")}
    end
  end

  def handle_event("select-example", %{"playground" => %{"example" => name}}, socket) do
    {code, example} =
      if name == "custom" do
        {socket.assigns.custom_code, "custom"}
      else
        {BlendendPlaygroundPhx.Examples.get(name) || socket.assigns.code, name}
      end

    {image_base64, error, render_ms} = render_code(code)

    {:noreply,
     socket
     |> assign(:form, to_form(%{"code" => code, "example" => example}, as: :playground))
     |> assign(:submitted?, true)
     |> assign(:image_base64, image_base64)
     |> assign(:error, error)
     |> assign(:render_ms, render_ms)
     |> assign(:code, code)
     |> assign(:example, example)}
  end

  @impl true
  def handle_info({:render_code, code}, socket) do
    {image_base64, error, render_ms} = render_code(code)

    {:noreply,
     socket
     |> assign(:submitted?, true)
     |> assign(:image_base64, image_base64)
     |> assign(:error, error)
     |> assign(:render_ms, render_ms)}
  end

  defp render_code(code) do
    start = System.monotonic_time()

    {image_base64, error} =
      case BlendendPlaygroundPhx.Renderer.render(code) do
        {:ok, base64} -> {base64, nil}
        {:error, reason} -> {nil, to_string(reason)}
      end

    elapsed_ms =
      System.monotonic_time()
      |> Kernel.-(start)
      |> System.convert_time_unit(:native, :millisecond)

    {image_base64, error, elapsed_ms}
  end

  defp maybe_assign_custom_code(socket, "custom", code) do
    assign(socket, :custom_code, code)
  end

  defp maybe_assign_custom_code(socket, _example, _code), do: socket

  defp default_code do
    """
    draw 420, 240 do
      clear(fill: rgb(242, 230, 216))
      rect(40, 40, 160, 80, fill: rgb(58, 102, 152))
      font = load_font("priv/fonts/AlegreyaSans-Regular.otf", 18)
      text(font, 40, 160, "Hello Blendend")
    end
    """
  end

  defp build_example_options(examples) do
    examples =
      Enum.reject(examples, fn example ->
        example == "custom"
      end)

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
