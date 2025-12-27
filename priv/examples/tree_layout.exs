# Experimenting and testing tree layout module
alias BlendendPlaygroundPhx.TreeLayout
use Blendend.Draw

orientation = :horizontal

tree = %{
  label: "Blendend",
  children: [
    %{
      label: "Shapes",
      children: [
        %{label: "Lines", children: []},
        %{label: "Curves", children: []},
        %{label: "Paths", children: []},
        %{
          label: "Transformations",
          children: [
            %{label: "Translate", children: []},
            %{label: "Scale", children: []},
            %{label: "Rotate", children: []}
          ]
        }
      ]
    },
    %{
      label: "Color",
      children: [
        %{label: "RGB", children: []},
        %{label: "Gradients", children: []},
        %{label: "Palettes", children: []}
      ]
    },
    %{
      label: "Text",
      children: [
        %{label: "Fonts", children: []},
        %{label: "Glyphs", children: []},
        %{label: "Layout", children: []}
      ]
    }
  ]
}

layout = TreeLayout.layout(tree, distance: 1.0, orientation: orientation)
nodes = layout.nodes
edges = layout.edges
node_map = Map.new(nodes, &{&1.id, &1})

spacing_x = 120.0
spacing_y = 120.0
padding = 50.0
radius = 2.0

xs = Enum.map(nodes, & &1.x)
ys = Enum.map(nodes, & &1.y)
min_x = Enum.min(xs)
max_x = Enum.max(xs)
min_y = Enum.min(ys)
max_y = Enum.max(ys)

tree_width = (max_x - min_x) * spacing_x
tree_height = (max_y - min_y) * spacing_y

width = max(1000, (tree_width + padding * 2) |> Float.ceil() |> trunc())
height = max(1060, (tree_height + padding * 2 + 60) |> Float.ceil() |> trunc())

origin_x = padding + (width - padding * 2 - tree_width) / 2 - min_x * spacing_x
origin_y = padding + 40 - min_y * spacing_y

point = fn node ->
  {origin_x + node.x * spacing_x, origin_y + node.y * spacing_y}
end

draw width, height do
  clear(fill: rgb(244, 244, 239))

  title_font = load_font("priv/fonts/AlegreyaSans-Regular.otf", 20.0)
  label_font = load_font("priv/fonts/MapleMono-Regular.otf", 12.0)

  text(title_font, 32, 36, "Tree layout (#{orientation}, Buchheim)", fill: rgb(35, 40, 50))

  edge_color = rgb(120, 130, 150, 180)

  Enum.each(edges, fn %{from: from_id, to: to_id} ->
    from = node_map[from_id]
    to = node_map[to_id]
    {x1, y1} = point.(from)
    {x2, y2} = point.(to)
    line(x1, y1, x2, y2, stroke: edge_color, stroke_width: 2.0)
  end)

  Enum.each(nodes, fn node ->
    {x, y} = point.(node)
    circle(x, y, radius, stroke: rgb(140, 55, 70), stroke_width: 1.5)
    text(label_font, x + radius + 8, y + 4, node.label, fill: rgb(35, 40, 50))
  end)
end
