defmodule B.Application do
  use Application

  @impl Application
  def start(_, _) do
    opts = [strategy: :one_for_one, name: NSYNC.Supervisor]
    Supervisor.start_link([B], opts)
  end
end
