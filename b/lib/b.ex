defmodule B do
  use Ecto.Repo, otp_app: :nsync, adapter: Ecto.Adapters.SQLite3

  @default_config [
    database: "tmp/b.db",
    show_sensitive_data_on_connection_error: false,
    journal_mode: :wal,
    cache_size: -64000,
    temp_store: :memory,
    foreign_keys: :off
  ]

  @impl Ecto.Repo
  def init(_context, config) do
    # Expect defaults to reflect on-device settings unless
    # explicitly overridden in the Application config
    {:ok, Keyword.merge(@default_config, config)}
  end
end
