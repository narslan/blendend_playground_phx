defmodule BlendendPlaygroundPhxWeb.BlendendColorPicker do
  use BlendendPlaygroundPhxWeb, :live_component

  alias Blendend.Image

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign_new(:label, fn -> "Color picker" end)
      |> assign_new(:on_pick, fn -> nil end)
      |> assign_new(:png_base64, fn -> nil end)
      |> assign_new(:picked, fn -> nil end)
      |> assign_new(:decode_error, fn -> nil end)

    socket =
      case assigns do
        %{png_base64: png_base64} when is_binary(png_base64) and byte_size(png_base64) > 0 ->
          current_hash = Map.get(socket.assigns, :png_hash)
          new_hash = :erlang.phash2(png_base64)

          socket =
            socket
            |> assign(assigns)
            |> assign(:src, "data:image/png;base64," <> png_base64)
            |> assign(:decode_error, nil)

          if current_hash == new_hash do
            socket
          else
            decode_png_to_image(socket, png_base64, new_hash)
          end

        _ ->
          socket
          |> assign(assigns)
          |> assign(:src, nil)
          |> assign(:decode_error, nil)
      end

    {:ok, socket}
  end

  @impl true
  def handle_event("pick-color", %{"x" => x, "y" => y}, socket) do
    x = normalize_int(x)
    y = normalize_int(y)

    rgba =
      case socket.assigns do
        %{image: image, img_w: w, img_h: h}
        when is_integer(x) and is_integer(y) and x >= 0 and y >= 0 and x < w and y < h ->
          try do
            Image.pixel_at!(image, x, y)
          rescue
            _ -> nil
          end

        _ ->
          nil
      end

    socket =
      if rgba do
        picked = %{
          x: x,
          y: y,
          rgba: rgba,
          hex: rgba_to_hex(rgba)
        }

        maybe_notify_parent(socket.assigns.on_pick, socket.id, picked)
        assign(socket, :picked, picked)
      else
        socket
      end

    {:noreply, socket}
  end

  defp decode_png_to_image(socket, png_base64, new_hash) do
    with {:ok, png} <- Base.decode64(png_base64),
         {:ok, image} <- safe_image_from_data(png) do
      {w, h} = Image.size!(image)

      socket
      |> assign(:png_hash, new_hash)
      |> assign(:image, image)
      |> assign(:img_w, w)
      |> assign(:img_h, h)
    else
      {:error, reason} ->
        socket
        |> assign(:png_hash, new_hash)
        |> assign(:image, nil)
        |> assign(:img_w, nil)
        |> assign(:img_h, nil)
        |> assign(:decode_error, to_string(reason))
    end
  end

  defp safe_image_from_data(png) do
    try do
      Image.from_data(png)
    rescue
      error -> {:error, Exception.message(error)}
    catch
      :exit, reason -> {:error, inspect(reason)}
      kind, reason -> {:error, "#{inspect(kind)}: #{inspect(reason)}"}
    end
  end

  defp maybe_notify_parent(nil, _id, _picked), do: :ok

  defp maybe_notify_parent(on_pick, id, picked) when is_atom(on_pick) do
    send(self(), {on_pick, %{id: id, picked: picked}})
    :ok
  end

  defp normalize_int(val) when is_integer(val), do: val
  defp normalize_int(val) when is_float(val), do: trunc(val)

  defp normalize_int(val) when is_binary(val) do
    case Integer.parse(val) do
      {int, _} -> int
      :error -> nil
    end
  end

  defp normalize_int(_), do: nil

  defp rgba_to_hex({r, g, b, _a}) do
    "#" <>
      hex2(r) <>
      hex2(g) <>
      hex2(b)
  end

  defp hex2(int) when is_integer(int) and int in 0..255 do
    int
    |> Integer.to_string(16)
    |> String.upcase()
    |> String.pad_leading(2, "0")
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class="grid gap-3">
      <div class="flex flex-wrap items-center justify-between gap-3">
        <p class="text-xs font-semibold uppercase tracking-[0.2em] text-base-content/60">
          {@label}
        </p>

        <%= if @picked do %>
          <div class="flex items-center gap-3">
            <div
              class="h-6 w-10 rounded-lg border border-slate-200 shadow-sm dark:border-slate-800"
              style={"background: rgba(#{elem(@picked.rgba, 0)}, #{elem(@picked.rgba, 1)}, #{elem(@picked.rgba, 2)}, #{elem(@picked.rgba, 3) / 255});"}
            />
            <p class="font-mono text-xs text-slate-600 dark:text-slate-300">
              {@picked.hex} · a={elem(@picked.rgba, 3)}
            </p>
          </div>
        <% end %>
      </div>

      <div class="relative overflow-hidden rounded-2xl border border-slate-200/70 bg-white/70 shadow-sm backdrop-blur dark:border-slate-800/60 dark:bg-slate-950/30">
        <%= if @src && !@decode_error do %>
          <img
            id={"#{@id}-img"}
            src={@src}
            alt="Color picker"
            phx-hook="BlendendColorPicker"
            data-img-width={@img_w}
            data-img-height={@img_h}
            class="block w-full select-none cursor-crosshair"
            draggable="false"
          />

          <div
            :if={@picked}
            aria-hidden="true"
            class="pointer-events-none absolute size-4 -translate-x-1/2 -translate-y-1/2 rounded-full ring-2 ring-white shadow-sm outline outline-1 outline-black/30"
            style={[
              "left: #{@picked.x / @img_w * 100}%; top: #{@picked.y / @img_h * 100}%;",
              "background: rgba(#{elem(@picked.rgba, 0)}, #{elem(@picked.rgba, 1)}, #{elem(@picked.rgba, 2)}, #{elem(@picked.rgba, 3) / 255});"
            ]}
          />
        <% else %>
          <div class="p-6 text-sm text-base-content/60">
            <%= if @decode_error do %>
              Pixel picking unavailable: {@decode_error}
            <% else %>
              Provide <span class="font-mono">png_base64</span> to render the picker.
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
