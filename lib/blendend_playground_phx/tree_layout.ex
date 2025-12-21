defmodule BlendendPlaygroundPhx.TreeLayout do
  @moduledoc """
  Computes a tidy tree layout using the Buchheim algorithm (as used by d3.tree).
  C. Buchheim, M. J Unger, and S. Leipert. Improving Walker's algorithm to run in linear time. In Proc. Graph Drawing (GD), 2002
  http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.16.8757
  The implementation here is a a port of the code at https://llimllib.github.io/pymag-trees/
  """

  @type tree :: %{label: term(), children: [tree()]}
  @type layout_node :: %{
          id: non_neg_integer(),
          label: term(),
          parent_id: non_neg_integer() | nil,
          x: float(),
          y: float()
        }
  @type edge :: %{from: non_neg_integer(), to: non_neg_integer()}

  defstruct [
    :id,
    :label,
    :parent,
    :children,
    :thread,
    :ancestor,
    :number,
    x: -1.0,
    y: 0.0,
    mod: 0.0,
    change: 0.0,
    shift: 0.0
  ]

  @spec layout(tree(), keyword()) :: %{nodes: [layout_node()], edges: [edge()]}
  def layout(tree, opts \\ []) do
    distance = Keyword.get(opts, :distance, 1.0)

    {root_id, nodes} = build_tree(tree)
    nodes = first_walk(nodes, root_id, distance)
    {nodes, min_x} = second_walk(nodes, root_id, 0.0, 0, nil)

    nodes =
      if min_x < 0 do
        third_walk(nodes, root_id, -min_x)
      else
        nodes
      end

    edges =
      nodes
      |> Map.values()
      |> Enum.flat_map(fn node ->
        Enum.map(node.children, fn child_id -> %{from: node.id, to: child_id} end)
      end)

    nodes =
      nodes
      |> Map.values()
      |> Enum.map(fn node ->
        %{
          id: node.id,
          label: node.label,
          parent_id: node.parent,
          x: node.x,
          y: node.y
        }
      end)

    %{nodes: nodes, edges: edges}
  end

  defp build_tree(tree) do
    {root_id, _next_id, nodes} = build_nodes(tree, nil, 0, 1, 0, %{})
    {root_id, nodes}
  end

  defp build_nodes(tree, parent_id, depth, number, next_id, nodes) do
    id = next_id
    children = Map.get(tree, :children, [])

    {child_ids, next_id, nodes} =
      children
      |> Enum.with_index(1)
      |> Enum.reduce({[], id + 1, nodes}, fn {child, index}, {ids, next_id, nodes} ->
        {child_id, next_id, nodes} = build_nodes(child, id, depth + 1, index, next_id, nodes)
        {[child_id | ids], next_id, nodes}
      end)

    label =
      tree
      |> Map.get(:label, Map.get(tree, :name, ""))
      |> to_string()

    node = %__MODULE__{
      id: id,
      label: label,
      parent: parent_id,
      children: Enum.reverse(child_ids),
      ancestor: id,
      number: number,
      y: depth
    }

    {id, next_id, Map.put(nodes, id, node)}
  end

  defp first_walk(nodes, v_id, distance) do
    node = nodes[v_id]

    if node.children == [] do
      case left_brother_id(nodes, v_id) do
        nil ->
          Map.put(nodes, v_id, %{node | x: 0.0})

        w_id ->
          w = nodes[w_id]
          Map.put(nodes, v_id, %{node | x: w.x + distance})
      end
    else
      default_ancestor_id = List.first(node.children)

      {nodes, _default_ancestor_id} =
        Enum.reduce(node.children, {nodes, default_ancestor_id}, fn child_id,
                                                                    {nodes, default_ancestor_id} ->
          nodes = first_walk(nodes, child_id, distance)
          apportion(nodes, child_id, default_ancestor_id, distance)
        end)

      nodes = execute_shifts(nodes, v_id)
      node = nodes[v_id]
      first_child = List.first(node.children)
      last_child = List.last(node.children)
      midpoint = (nodes[first_child].x + nodes[last_child].x) / 2.0

      case left_brother_id(nodes, v_id) do
        nil ->
          Map.put(nodes, v_id, %{node | x: midpoint})

        w_id ->
          w = nodes[w_id]
          x = w.x + distance
          Map.put(nodes, v_id, %{node | x: x, mod: x - midpoint})
      end
    end
  end

  defp apportion(nodes, v_id, default_ancestor_id, distance) do
    case left_brother_id(nodes, v_id) do
      nil ->
        {nodes, default_ancestor_id}

      w_id ->
        vir_id = v_id
        vor_id = v_id
        vil_id = w_id
        vol_id = lmost_sibling_id(nodes, v_id)

        if is_nil(vol_id) do
          {nodes, default_ancestor_id}
        else
          sir = nodes[vir_id].mod
          sor = nodes[vor_id].mod
          sil = nodes[vil_id].mod
          sol = nodes[vol_id].mod

          {nodes, default_ancestor_id, vil_id, vir_id, vol_id, vor_id, sil, sir, sol, sor} =
            apportion_loop(
              nodes,
              v_id,
              default_ancestor_id,
              distance,
              vil_id,
              vir_id,
              vol_id,
              vor_id,
              sil,
              sir,
              sol,
              sor
            )

          {nodes, default_ancestor_id} =
            cond do
              right(nodes, vil_id) && is_nil(right(nodes, vor_id)) ->
                r_id = right(nodes, vil_id)
                vor = nodes[vor_id]

                {Map.put(nodes, vor_id, %{vor | thread: r_id, mod: vor.mod + sil - sor}),
                 default_ancestor_id}

              left(nodes, vir_id) && is_nil(left(nodes, vol_id)) ->
                l_id = left(nodes, vir_id)
                vol = nodes[vol_id]
                {Map.put(nodes, vol_id, %{vol | thread: l_id, mod: vol.mod + sir - sol}), v_id}

              true ->
                {nodes, default_ancestor_id}
            end

          {nodes, default_ancestor_id}
        end
    end
  end

  defp apportion_loop(
         nodes,
         v_id,
         default_ancestor_id,
         distance,
         vil_id,
         vir_id,
         vol_id,
         vor_id,
         sil,
         sir,
         sol,
         sor
       ) do
    case {right(nodes, vil_id), left(nodes, vir_id)} do
      {nil, _} ->
        {nodes, default_ancestor_id, vil_id, vir_id, vol_id, vor_id, sil, sir, sol, sor}

      {_, nil} ->
        {nodes, default_ancestor_id, vil_id, vir_id, vol_id, vor_id, sil, sir, sol, sor}

      {vil_right, vir_left} ->
        vol_next = left(nodes, vol_id)
        vor_next = right(nodes, vor_id)

        if is_nil(vol_next) or is_nil(vor_next) do
          {nodes, default_ancestor_id, vil_id, vir_id, vol_id, vor_id, sil, sir, sol, sor}
        else
          vil_id = vil_right
          vir_id = vir_left
          vol_id = vol_next
          vor_id = vor_next

          vor = nodes[vor_id]
          nodes = Map.put(nodes, vor_id, %{vor | ancestor: v_id})
          shift = nodes[vil_id].x + sil - (nodes[vir_id].x + sir) + distance

          {nodes, sir, sor} =
            if shift > 0 do
              ancestor_id = ancestor(nodes, vil_id, v_id, default_ancestor_id)
              nodes = move_subtree(nodes, ancestor_id, v_id, shift)
              {nodes, sir + shift, sor + shift}
            else
              {nodes, sir, sor}
            end

          sil = sil + nodes[vil_id].mod
          sir = sir + nodes[vir_id].mod
          sol = sol + nodes[vol_id].mod
          sor = sor + nodes[vor_id].mod

          apportion_loop(
            nodes,
            v_id,
            default_ancestor_id,
            distance,
            vil_id,
            vir_id,
            vol_id,
            vor_id,
            sil,
            sir,
            sol,
            sor
          )
        end
    end
  end

  defp move_subtree(nodes, wl_id, wr_id, shift) do
    wl = nodes[wl_id]
    wr = nodes[wr_id]
    subtrees = wr.number - wl.number
    shift_per_subtree = shift / subtrees

    wr = %{wr | change: wr.change - shift_per_subtree, shift: wr.shift + shift}
    wl = %{wl | change: wl.change + shift_per_subtree}
    wr = %{wr | x: wr.x + shift, mod: wr.mod + shift}

    nodes
    |> Map.put(wl_id, wl)
    |> Map.put(wr_id, wr)
  end

  defp execute_shifts(nodes, v_id) do
    node = nodes[v_id]

    {nodes, _shift, _change} =
      node.children
      |> Enum.reverse()
      |> Enum.reduce({nodes, 0.0, 0.0}, fn child_id, {nodes, shift, change} ->
        child = nodes[child_id]
        child = %{child | x: child.x + shift, mod: child.mod + shift}
        nodes = Map.put(nodes, child_id, child)
        change = change + child.change
        shift = shift + child.shift + change
        {nodes, shift, change}
      end)

    nodes
  end

  defp ancestor(nodes, vil_id, v_id, default_ancestor_id) do
    parent_id = nodes[v_id].parent

    if parent_id && nodes[vil_id].ancestor in nodes[parent_id].children do
      nodes[vil_id].ancestor
    else
      default_ancestor_id
    end
  end

  defp second_walk(nodes, v_id, m, depth, min) do
    node = nodes[v_id]
    x = node.x + m
    node = %{node | x: x, y: depth}
    nodes = Map.put(nodes, v_id, node)
    min = if is_nil(min) or x < min, do: x, else: min

    Enum.reduce(node.children, {nodes, min}, fn child_id, {nodes, min} ->
      second_walk(nodes, child_id, m + node.mod, depth + 1, min)
    end)
  end

  defp third_walk(nodes, v_id, shift) do
    node = nodes[v_id]
    nodes = Map.put(nodes, v_id, %{node | x: node.x + shift})

    Enum.reduce(node.children, nodes, fn child_id, nodes ->
      third_walk(nodes, child_id, shift)
    end)
  end

  defp left(_nodes, nil), do: nil

  defp left(nodes, id) do
    node = nodes[id]
    node.thread || List.first(node.children)
  end

  defp right(_nodes, nil), do: nil

  defp right(nodes, id) do
    node = nodes[id]
    node.thread || List.last(node.children)
  end

  defp left_brother_id(nodes, id) do
    node = nodes[id]

    case node.parent do
      nil ->
        nil

      parent_id ->
        siblings = nodes[parent_id].children
        index = Enum.find_index(siblings, &(&1 == id))

        if index && index > 0 do
          Enum.at(siblings, index - 1)
        else
          nil
        end
    end
  end

  defp lmost_sibling_id(nodes, id) do
    node = nodes[id]

    case node.parent do
      nil ->
        nil

      parent_id ->
        case nodes[parent_id].children do
          [first | _] when first != id -> first
          _ -> nil
        end
    end
  end
end
