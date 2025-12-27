defmodule BlendendPlaygroundPhx.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    :ok = BlendendPlaygroundPhx.Palette.init_cache()

    children = [
      BlendendPlaygroundPhx.Fonts,
      {Phoenix.PubSub, name: BlendendPlaygroundPhx.PubSub},
      BlendendPlaygroundPhxWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BlendendPlaygroundPhx.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BlendendPlaygroundPhxWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
