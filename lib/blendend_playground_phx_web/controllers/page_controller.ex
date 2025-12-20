defmodule BlendendPlaygroundPhxWeb.PageController do
  use BlendendPlaygroundPhxWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
