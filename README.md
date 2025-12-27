# BlendendPlaygroundPhx

A web UI for experimenting with [`blendend`](https://github.com/narslan/blendend): 
Safety: the backend evaluates the code you type. Run it only on a trusted machine.

## Features
- **Playground** – live sketchbook for `blendend` snippets. 
- **Swatches** – palette browser rendered as collages. It shows how colors interact on a composition.

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Blendend color picker component

`BlendendPlaygroundPhxWeb.BlendendColorPicker` is a reusable LiveComponent that renders a PNG and lets users click to pick a pixel color server-side via `Blendend.Image.pixel_at!/3`.

Example usage in a LiveView:

```elixir
<.live_component
  module={BlendendPlaygroundPhxWeb.BlendendColorPicker}
  id="picker"
  label="Pick a color"
  png_base64={@image_base64}
  on_pick={:color_picked}
/>
```

Handle the selected color in the LiveView:

```elixir
@impl true
def handle_info({:color_picked, %{id: _id, picked: picked}}, socket) do
  # picked = %{x: x, y: y, rgba: {r, g, b, a}, hex: "#RRGGBB"}
  {:noreply, assign(socket, picked_color: picked)}
end
```


## Licenses

- This project is released under the MIT License (see `LICENSE`).
- `blend2d` is licensed under the zlib license.
- The fonts under `priv/fonts/` are distributed under the SIL Open Font License.
- [Chromotome Palettes](https://github.com/kgolid/chromotome) is distributed under MIT License.
- More palettes are taken from takawo's sketches (https://openprocessing.org/user/6533) are released under https://creativecommons.org/licenses/by-nc-sa/3.0/
