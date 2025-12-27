defmodule BlendendPlaygroundPhxWeb.SwatchesLive do
  use BlendendPlaygroundPhxWeb, :live_view

  alias BlendendPlaygroundPhx.{Palette, RgbPicker, Swatches}

  @impl true
  def mount(_params, _session, socket) do
    sources = Palette.palette_sources()
    palettes = Palette.palettes_by_source()
    {source, scheme} = default_selection(sources, palettes)

    socket =
      socket
      |> assign(:sources, sources)
      |> assign(:palettes, palettes)
      |> assign(:source_options, source_options(sources))
      |> assign(:scheme_options, scheme_options(palettes, source))
      |> assign(:form, to_form(%{"source" => source, "scheme" => scheme}, as: :swatches))
      |> assign(:image_base64, nil)
      |> assign(:error, nil)
      |> assign(:rgb_picker_open?, false)
      |> assign(:rgb_b, 128)
      |> assign(:rgb_form, to_form(%{"b" => 128}, as: :rgb))
      |> assign(:rgb_base64, nil)
      |> assign(:rgb_error, nil)
      |> assign(:rgb_picked, nil)

    if (connected?(socket) and source) && scheme do
      send(self(), {:render_swatches, source, scheme})
    end

    {:ok, socket}
  end

  @impl true
  def handle_event("change", %{"swatches" => params}, socket) do
    source = normalize_value(params["source"])
    scheme = normalize_value(params["scheme"])

    {source, scheme} =
      normalize_selection(source, scheme, socket.assigns.sources, socket.assigns.palettes)

    {image_base64, error} = render_swatches(source, scheme)

    {:noreply,
     socket
     |> assign(:scheme_options, scheme_options(socket.assigns.palettes, source))
     |> assign(:form, to_form(%{"source" => source, "scheme" => scheme}, as: :swatches))
     |> assign(:image_base64, image_base64)
     |> assign(:error, error)}
  end

  @impl true
  def handle_event("toggle-rgb-picker", _params, socket) do
    open? = !socket.assigns.rgb_picker_open?
    socket = assign(socket, :rgb_picker_open?, open?)

    socket =
      if open? do
        {rgb_base64, rgb_error} = render_rgb_plane(socket.assigns.rgb_b)
        assign(socket, rgb_base64: rgb_base64, rgb_error: rgb_error)
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("rgb-change", %{"rgb" => %{"b" => b}}, socket) do
    b = normalize_b(b)

    socket =
      socket
      |> assign(:rgb_b, b)
      |> assign(:rgb_form, to_form(%{"b" => b}, as: :rgb))

    socket =
      if socket.assigns.rgb_picker_open? do
        {rgb_base64, rgb_error} = render_rgb_plane(b)
        assign(socket, rgb_base64: rgb_base64, rgb_error: rgb_error)
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:render_swatches, source, scheme}, socket) do
    {image_base64, error} = render_swatches(source, scheme)
    {:noreply, assign(socket, image_base64: image_base64, error: error)}
  end

  @impl true
  def handle_info({:swatches_rgb_picked, %{picked: picked}}, socket) do
    {:noreply, assign(socket, :rgb_picked, picked)}
  end

  defp render_swatches(nil, _scheme), do: {nil, nil}
  defp render_swatches(_source, nil), do: {nil, nil}

  defp render_swatches(source, scheme) do
    palette =
      try do
        Palette.palette_by_name(scheme, source)
      rescue
        ArgumentError -> nil
      end

    if palette do
      case Swatches.render(palette) do
        {:ok, base64} -> {base64, nil}
        {:error, reason} -> {nil, inspect(reason)}
      end
    else
      {nil, "palette not found"}
    end
  end

  defp default_selection([], _palettes), do: {nil, nil}

  defp default_selection([source | _], palettes) do
    schemes = Map.get(palettes, source, [])
    {source, List.first(schemes)}
  end

  defp normalize_selection(nil, _scheme, sources, palettes) do
    default_selection(sources, palettes)
  end

  defp normalize_selection(source, scheme, _sources, palettes) do
    schemes = Map.get(palettes, source, [])

    if scheme in schemes do
      {source, scheme}
    else
      {source, List.first(schemes)}
    end
  end

  defp source_options(sources), do: Enum.map(sources, &{&1, &1})

  defp scheme_options(palettes, source) do
    palettes
    |> Map.get(source, [])
    |> Enum.map(&{&1, &1})
  end

  defp normalize_value(nil), do: nil
  defp normalize_value(""), do: nil
  defp normalize_value(value), do: value

  defp normalize_b(val) when is_integer(val), do: min(max(val, 0), 255)

  defp normalize_b(val) when is_binary(val) do
    case Integer.parse(val) do
      {int, _} -> normalize_b(int)
      :error -> 128
    end
  end

  defp normalize_b(_), do: 128

  defp render_rgb_plane(b) do
    case RgbPicker.render_rg_plane(b, 256) do
      {:ok, base64} -> {base64, nil}
      {:error, reason} -> {nil, to_string(reason)}
    end
  end
end
