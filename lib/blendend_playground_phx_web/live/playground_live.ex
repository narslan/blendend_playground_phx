defmodule BlendendPlaygroundPhxWeb.PlaygroundLive do
  use BlendendPlaygroundPhxWeb, :live_view

  @view_modes ~w(split preview)

  @impl true
  def mount(params, _session, socket) do
    custom_code = BlendendPlaygroundPhx.Examples.get("custom") || default_code()
    code = custom_code
    examples = BlendendPlaygroundPhx.Examples.all()
    example_options = build_example_options(examples)
    view_mode = if Map.get(params, "view") in @view_modes, do: params["view"], else: "split"

    socket =
      socket
      |> assign(:form, to_form(%{"code" => code, "example" => "custom"}, as: :playground))
      |> assign(:save_form, to_form(%{"name" => ""}, as: :save))
      |> assign(:submitted?, false)
      |> assign(:image_base64, nil)
      |> assign(:error, nil)
      |> assign(:render_ms, nil)
      |> assign(:rendering?, false)
      |> assign(:render_ref, nil)
      |> assign(:pending_render_code, nil)
      |> assign(:examples, examples)
      |> assign(:example_options, example_options)
      |> assign(:code, code)
      |> assign(:custom_code, custom_code)
      |> assign(:example, "custom")
      |> assign(:view_mode, view_mode)
      |> assign(:editor_expanded?, false)

    socket =
      if connected?(socket) do
        request_render(socket, code)
      else
        socket
      end

    {:ok, socket}
  end

  @impl true
  def handle_event("code-change", %{"playground" => %{"code" => code}}, socket) do
    example = socket.assigns.example

    {:noreply,
     socket
     |> assign(:form, to_form(%{"code" => code, "example" => example}, as: :playground))
     |> assign(:code, code)
     |> assign(:example, example)
     |> maybe_assign_custom_code(example, code)
     |> request_render(code)}
  end

  @impl true
  def handle_event("render", _params, socket) do
    {:noreply, request_render(socket, socket.assigns.code)}
  end

  @impl true
  def handle_event("save-code", %{"playground" => %{"code" => code}} = params, socket) do
    example = socket.assigns.example

    case Map.get(params, "action") do
      "format" ->
        case BlendendPlaygroundPhx.Examples.format(example, code) do
          {:ok, formatted_code} ->
            {:noreply,
             socket
             |> assign(
               :form,
               to_form(%{"code" => formatted_code, "example" => example}, as: :playground)
             )
             |> assign(:code, formatted_code)
             |> maybe_assign_custom_code(example, formatted_code)
             |> request_render(formatted_code)
             |> put_flash(:info, "Formatted #{example}.exs")}

          {:error, :unknown_example} ->
            {:noreply, put_flash(socket, :error, "Unknown example selected.")}

          {:error, reason} ->
            {:noreply, put_flash(socket, :error, "Unable to format: #{to_string(reason)}")}
        end

      _ ->
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
  end

  @impl true
  def handle_event("save-as", %{"save" => %{"name" => name}}, socket) do
    save_form = to_form(%{"name" => name}, as: :save)

    case BlendendPlaygroundPhx.Examples.save_new(name, socket.assigns.code) do
      {:ok, saved_name} ->
        examples = BlendendPlaygroundPhx.Examples.all()
        example_options = build_example_options(examples)
        code = socket.assigns.code

        {:noreply,
         socket
         |> assign(:examples, examples)
         |> assign(:example_options, example_options)
         |> assign(:form, to_form(%{"code" => code, "example" => saved_name}, as: :playground))
         |> assign(:example, saved_name)
         |> assign(:save_form, to_form(%{"name" => ""}, as: :save))
         |> request_render(code)
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

  @impl true
  def handle_event("set-view-mode", %{"mode" => mode}, socket) when mode in @view_modes do
    {:noreply, assign(socket, :view_mode, mode)}
  end

  @impl true
  def handle_event("toggle-editor-size", _params, socket) do
    {:noreply, update(socket, :editor_expanded?, &(!&1))}
  end

  def handle_event("select-example", %{"playground" => %{"example" => name}}, socket) do
    {code, example} =
      if name == "custom" do
        {socket.assigns.custom_code, "custom"}
      else
        {BlendendPlaygroundPhx.Examples.get(name) || socket.assigns.code, name}
      end

    {:noreply,
     socket
     |> assign(:form, to_form(%{"code" => code, "example" => example}, as: :playground))
     |> assign(:code, code)
     |> assign(:example, example)
     |> request_render(code)}
  end

  @impl true
  def handle_info({:render_complete, ref, result, render_ms}, socket) do
    if socket.assigns.render_ref != ref do
      {:noreply, socket}
    else
      {image_base64, error} = normalize_render_result(result)
      pending_code = socket.assigns.pending_render_code

      socket =
        socket
        |> assign(:submitted?, true)
        |> assign(:image_base64, image_base64)
        |> assign(:error, error)
        |> assign(:render_ms, render_ms)
        |> assign(:rendering?, false)
        |> assign(:render_ref, nil)
        |> assign(:pending_render_code, nil)

      socket =
        if is_binary(pending_code) do
          request_render(socket, pending_code)
        else
          socket
        end

      {:noreply, socket}
    end
  end

  defp request_render(socket, code) when is_binary(code) do
    if socket.assigns.rendering? do
      assign(socket, :pending_render_code, code)
    else
      start_render_task(socket, code)
    end
  end

  defp start_render_task(socket, code) when is_binary(code) do
    parent = self()
    ref = make_ref()

    {:ok, _pid} =
      Task.start(fn ->
        start = System.monotonic_time()

        result =
          try do
            BlendendPlaygroundPhx.Renderer.render(code)
          catch
            kind, reason ->
              {:error, Exception.format(kind, reason, __STACKTRACE__)}
          end

        elapsed_ms =
          System.monotonic_time()
          |> Kernel.-(start)
          |> System.convert_time_unit(:native, :millisecond)

        send(parent, {:render_complete, ref, result, elapsed_ms})
      end)

    socket
    |> assign(:submitted?, true)
    |> assign(:rendering?, true)
    |> assign(:render_ref, ref)
    |> assign(:render_ms, nil)
    |> assign(:error, nil)
  end

  defp normalize_render_result({:ok, base64}) when is_binary(base64) and base64 != "" do
    {base64, nil}
  end

  defp normalize_render_result({:ok, base64}) when is_binary(base64) do
    {nil, "Renderer returned an empty image."}
  end

  defp normalize_render_result({:error, reason}) do
    message = reason |> to_string() |> String.trim()
    message = if message == "", do: "Unknown render error.", else: message
    {nil, message}
  end

  defp normalize_render_result(other) do
    {nil, "Unexpected render result: #{inspect(other)}"}
  end

  defp maybe_assign_custom_code(socket, "custom", code) do
    assign(socket, :custom_code, code)
  end

  defp maybe_assign_custom_code(socket, _example, _code), do: socket

  defp default_code do
    """
    width = 420
    height = 420
    draw width, height do
      clear(fill: rgb(242, 230, 216))
      rect(40, 40, 160, 80, fill: rgb(58, 102, 152))
      font = font("AlegreyaSans", 18)
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
