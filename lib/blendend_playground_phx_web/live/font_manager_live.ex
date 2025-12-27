defmodule BlendendPlaygroundPhxWeb.FontManagerLive do
  use BlendendPlaygroundPhxWeb, :live_view

  alias BlendendPlaygroundPhx.{FontPreview, Fonts}

  @default_sample "Hamburgefonts . 0123"
  @default_bg "#0E0E10"
  @default_fg "#EEEEEE"

  @impl true
  def mount(_params, _session, socket) do
    fonts = Fonts.all()
    {selected_font_id, selected_style} = default_selection(fonts)

    socket =
      socket
      |> assign(:fonts, fonts)
      |> assign(:filter, "")
      |> assign(:filtered_fonts, filter_fonts(fonts, ""))
      |> assign(:selected_font_id, selected_font_id)
      |> assign(:selected_style, selected_style)
      |> assign(:sample_text, @default_sample)
      |> assign(:font_size, 48)
      |> assign(:bg_hex, @default_bg)
      |> assign(:fg_hex, @default_fg)
      |> assign(:controls_open?, true)
      |> assign(:preview_base64, nil)
      |> assign(:preview_error, nil)
      |> assign(:preview_loading?, false)
      |> assign(:preview_request_id, 0)
      |> assign(:list_form, to_form(%{"filter" => ""}, as: :fonts))
      |> assign(
        :preview_form,
        to_form(
          %{
            "text" => @default_sample,
            "size" => 48,
            "style" => selected_style,
            "bg" => @default_bg,
            "fg" => @default_fg
          },
          as: :preview
        )
      )

    socket =
      socket
      |> assign_selected_font()
      |> assign_style_options()

    socket =
      if connected?(socket) do
        request_preview_render(socket)
      else
        socket
      end

    {:ok, socket}
  end

  @impl true
  def handle_event("filter-change", %{"fonts" => %{"filter" => filter}}, socket) do
    filter = filter || ""
    filtered = filter_fonts(socket.assigns.fonts, filter)

    {:noreply,
     socket
     |> assign(:filter, filter)
     |> assign(:filtered_fonts, filtered)
     |> assign(:list_form, to_form(%{"filter" => filter}, as: :fonts))}
  end

  @impl true
  def handle_event("select-font", %{"id" => id}, socket) do
    id = to_string(id)

    {selected_style, preview_form} =
      case Enum.find(socket.assigns.fonts, &(&1.id == id)) do
        nil ->
          {socket.assigns.selected_style, socket.assigns.preview_form}

        font ->
          style = font.variations |> List.first() |> Map.get(:style)

          {style,
           to_form(
             %{
               "text" => socket.assigns.sample_text,
               "size" => socket.assigns.font_size,
               "style" => style,
               "bg" => socket.assigns.bg_hex,
               "fg" => socket.assigns.fg_hex
             },
             as: :preview
           )}
      end

    {:noreply,
     socket
     |> assign(:selected_font_id, id)
     |> assign(:selected_style, selected_style)
     |> assign(:preview_form, preview_form)
     |> assign_selected_font()
     |> assign_style_options()
     |> request_preview_render()}
  end

  @impl true
  def handle_event("preview-change", %{"preview" => params}, socket) do
    text = Map.get(params, "text", socket.assigns.sample_text)
    style = Map.get(params, "style", socket.assigns.selected_style)

    size =
      normalize_int(Map.get(params, "size", socket.assigns.font_size), socket.assigns.font_size)

    bg_hex = normalize_hex_color(Map.get(params, "bg", socket.assigns.bg_hex), @default_bg)
    fg_hex = normalize_hex_color(Map.get(params, "fg", socket.assigns.fg_hex), @default_fg)

    {:noreply,
     socket
     |> assign(:sample_text, text)
     |> assign(:selected_style, style)
     |> assign(:font_size, size)
     |> assign(:bg_hex, bg_hex)
     |> assign(:fg_hex, fg_hex)
     |> assign(
       :preview_form,
       to_form(
         %{"text" => text, "size" => size, "style" => style, "bg" => bg_hex, "fg" => fg_hex},
         as: :preview
       )
     )
     |> request_preview_render()}
  end

  @impl true
  def handle_event("refresh-fonts", _params, socket) do
    :ok = Fonts.refresh()
    fonts = Fonts.all()

    {selected_font_id, selected_style} =
      ensure_selection(fonts, socket.assigns.selected_font_id, socket.assigns.selected_style)

    {:noreply,
     socket
     |> assign(:fonts, fonts)
     |> assign(:filtered_fonts, filter_fonts(fonts, socket.assigns.filter))
     |> assign(:selected_font_id, selected_font_id)
     |> assign(:selected_style, selected_style)
     |> assign(
       :preview_form,
       to_form(
         %{
           "text" => socket.assigns.sample_text,
           "size" => socket.assigns.font_size,
           "style" => selected_style,
           "bg" => socket.assigns.bg_hex,
           "fg" => socket.assigns.fg_hex
         },
         as: :preview
       )
     )
     |> assign_selected_font()
     |> assign_style_options()
     |> request_preview_render()}
  end

  @impl true
  def handle_event("toggle-controls", _params, socket) do
    {:noreply, update(socket, :controls_open?, &(!&1))}
  end

  @impl true
  def handle_info({:font_preview_rendered, request_id, result}, socket) do
    socket =
      if request_id == socket.assigns.preview_request_id do
        case result do
          {:ok, base64} ->
            socket
            |> assign(:preview_base64, base64)
            |> assign(:preview_error, nil)
            |> assign(:preview_loading?, false)

          {:error, reason} ->
            socket
            |> assign(:preview_error, to_string(reason))
            |> assign(:preview_loading?, false)
        end
      else
        socket
      end

    {:noreply, socket}
  end

  defp request_preview_render(socket) do
    id = socket.assigns.selected_font_id
    style = socket.assigns.selected_style

    socket =
      socket
      |> assign(:preview_loading?, true)
      |> assign(:preview_error, nil)
      |> update(:preview_request_id, &(&1 + 1))

    request_id = socket.assigns.preview_request_id

    lv_pid = self()

    Task.start(fn ->
      result =
        with true <- is_binary(id) and id != "",
             {:ok, variation} <- Fonts.lookup(id, style) do
          FontPreview.render(variation, %{
            "text" => socket.assigns.sample_text,
            "size" => socket.assigns.font_size,
            "bg" => socket.assigns.bg_hex,
            "fg" => socket.assigns.fg_hex
          })
        else
          _ -> {:error, "Select a font first"}
        end

      send(lv_pid, {:font_preview_rendered, request_id, result})
    end)

    socket
  end

  defp assign_selected_font(socket) do
    selected =
      Enum.find(socket.assigns.fonts, fn font ->
        font.id == socket.assigns.selected_font_id
      end)

    assign(socket, :selected_font, selected)
  end

  defp assign_style_options(%{assigns: %{selected_font: nil}} = socket) do
    assign(socket, :style_options, [])
  end

  defp assign_style_options(socket) do
    style_options =
      socket.assigns.selected_font.variations
      |> Enum.map(fn var ->
        {"#{var.style} · #{var.weight}", var.style}
      end)

    assign(socket, :style_options, style_options)
  end

  defp filter_fonts(fonts, filter) when is_binary(filter) do
    f = filter |> String.trim() |> String.downcase()

    if f == "" do
      fonts
    else
      Enum.filter(fonts, fn font ->
        String.contains?(String.downcase(font.family), f)
      end)
    end
  end

  defp default_selection([]), do: {nil, nil}

  defp default_selection([font | _]) do
    {font.id, font.variations |> List.first() |> Map.get(:style)}
  end

  defp ensure_selection([], _id, _style), do: {nil, nil}

  defp ensure_selection(fonts, id, style) do
    case Enum.find(fonts, &(&1.id == id)) do
      nil ->
        default_selection(fonts)

      font ->
        styles = Enum.map(font.variations, & &1.style)

        if style in styles do
          {id, style}
        else
          {id, font.variations |> List.first() |> Map.get(:style)}
        end
    end
  end

  defp normalize_int(val, _default) when is_integer(val), do: val

  defp normalize_int(val, default) when is_binary(val) do
    case Integer.parse(val) do
      {int, _} -> int
      :error -> default
    end
  end

  defp normalize_int(_val, default), do: default

  defp normalize_hex_color(val, fallback) when is_binary(val) do
    hex = String.trim(val)

    cond do
      Regex.match?(~r/^#[0-9A-Fa-f]{6}$/, hex) -> String.upcase(hex)
      true -> fallback
    end
  end

  defp normalize_hex_color(_val, fallback), do: fallback
end
