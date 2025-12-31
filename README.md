# BlendendPlaygroundPhx

A web UI for experimenting with [`blendend`](https://github.com/narslan/blendend): 
Safety: the backend evaluates the code you type. Run it only on a trusted machine.

## Features
- **Playground** – live sketchbook for `blendend` snippets. 
- **Swatches** – palette browser rendered as collages. It shows how colors interact on a composition.
- **Font Manager** – lists scanned fonts and renders a Blendend-powered preview. Supports unicode escapes (e.g. `\\u{1301C}`), size, and color controls.

## Visual Overview

### Swatches & Font Manager

| Page | Preview |
| --- | --- |
| Swatches | <img src="docs/swatches.png" width="640" alt="Swatches page preview" /> |
| Font Manager | <img src="docs/font_manager.png" width="640" alt="Font Manager page preview" /> |

### Playground Demos

| Axis histogram trees | Axis playground | Burn grid |
| --- | --- | --- |
| <img src="docs/axis_histogram_trees-fs8.png" width="260" alt="Axis histogram trees demo output" /> | <img src="docs/axis_playground-fs8.png" width="260" alt="Axis playground demo output" /> | <img src="docs/burn_grid-fs8.png" width="260" alt="Burn grid demo output" /> |

| Circle of fifths | Curtains | Daisy field |
| --- | --- | --- |
| <img src="docs/circle_of_fifths-fs8.png" width="260" alt="Circle of fifths demo output" /> | <img src="docs/curtains-fs8.png" width="260" alt="Curtains demo output" /> | <img src="docs/daisy_field-fs8.png" width="260" alt="Daisy field demo output" /> |

| Floral wave | Font tiles | Font tiles 2 |
| --- | --- | --- |
| <img src="docs/floral_wave-fs8.png" width="260" alt="Floral wave demo output" /> | <img src="docs/font_tiles-fs8.png" width="260" alt="Font tiles demo output" /> | <img src="docs/font_tiles2-fs8.png" width="260" alt="Font tiles 2 demo output" /> |

| Night house | Path flatten | Priform |
| --- | --- | --- |
| <img src="docs/night_house-fs8.png" width="260" alt="Night house demo output" /> | <img src="docs/path_flatten-fs8.png" width="260" alt="Path flatten demo output" /> | <img src="docs/priform-fs8.png" width="260" alt="Priform demo output" /> |

| Scale experiments | Table | Watercolor 2 |
| --- | --- | --- |
| <img src="docs/scale_experiments-fs8.png" width="260" alt="Scale experiments demo output" /> | <img src="docs/table-fs8.png" width="260" alt="Table demo output" /> | <img src="docs/watercolor2-fs8.png" width="260" alt="Watercolor 2 demo output" /> |

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Licenses

- This project is released under the MIT License (see `LICENSE`).
- `blend2d` is licensed under the zlib license.
- The fonts under `priv/fonts/` are distributed under the SIL Open Font License.
- [Chromotome Palettes](https://github.com/kgolid/chromotome) is distributed under MIT License.
- More palettes are imported from (https://github.com/BlakeRMills/MetBrewer) and d3.js.
