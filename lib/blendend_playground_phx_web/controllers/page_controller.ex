defmodule BlendendPlaygroundPhxWeb.PageController do
  use BlendendPlaygroundPhxWeb, :controller

  def home(conn, _params) do
    redirect(conn, to: ~p"/playground")
  end
end
