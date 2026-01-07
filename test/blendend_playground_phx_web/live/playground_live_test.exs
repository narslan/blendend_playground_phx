defmodule BlendendPlaygroundPhxWeb.PlaygroundLiveTest do
  use BlendendPlaygroundPhxWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  defp eventually(view, fun, attempts \\ 50) when is_function(fun, 0) do
    Enum.reduce_while(1..attempts, nil, fn _attempt, _acc ->
      if fun.() do
        {:halt, :ok}
      else
        _ = render(view)
        {:cont, nil}
      end
    end) || flunk("condition not met after #{attempts} attempts")
  end

  test "switches between split and full width preview", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/playground")

    assert has_element?(view, "#playground-view-toggle")
    assert has_element?(view, "#playground-editor-pane")
    assert has_element?(view, "#playground-preview-pane")
    assert has_element?(view, "#playground-editor-toggle-size")
    assert has_element?(view, "#playground-code-cursor")

    _ = view |> element("#playground-view-preview") |> render_click()

    refute has_element?(view, "#playground-editor-pane")
    assert has_element?(view, "#playground-preview-pane")

    _ = view |> element("#playground-view-split") |> render_click()

    assert has_element?(view, "#playground-editor-pane")
    assert has_element?(view, "#playground-preview-pane")
  end

  test "formats the current example via the Format button", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/playground")

    assert has_element?(view, "#playground-format")

    unformatted = """
    draw 420,240 do
    clear(fill: rgb(242,230,216))
    end
    """

    _ =
      view
      |> form("#playground-form", playground: %{code: unformatted})
      |> render_submit(%{"action" => "format"})

    refute has_element?(view, "#playground-code", "420,240")
    refute has_element?(view, "#playground-code", "242,230,216")
    assert has_element?(view, "#playground-code", "420, 240")
    assert has_element?(view, "#playground-code", "242, 230, 216")
  end

  test "can trigger a render without editing", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/playground")

    assert has_element?(view, "#playground-render")

    _ =
      eventually(view, fn ->
        has_element?(view, "#playground-render:not([disabled])")
      end)

    _ = view |> element("#playground-render") |> render_click()

    _ =
      eventually(view, fn ->
        has_element?(view, "#playground-render-image") or
          has_element?(view, "#playground-render-error")
      end)
  end
end
