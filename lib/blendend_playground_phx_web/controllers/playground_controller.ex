defmodule BlendendPlaygroundPhxWeb.PlaygroundController do
  use BlendendPlaygroundPhxWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end
end
