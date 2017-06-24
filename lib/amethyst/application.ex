defmodule Amethyst.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    {:ok, client} = ExIrc.start_link!

    children = [
      # Define workers and child supervisors to be supervised
      worker(ExampleConnectionHandler, [client]),
      # here's where we specify the channels to join:
      worker(ExampleLoginHandler, [client, ["#magic"]])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Amethyst.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
