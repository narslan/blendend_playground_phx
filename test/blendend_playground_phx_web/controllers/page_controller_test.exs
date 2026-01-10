defmodule BlendendPlaygroundPhxWeb.PageControllerTest do
  use BlendendPlaygroundPhxWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn, 302) == ~p"/playground"
  end
end
