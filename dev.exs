#
# Copy from Oban.Web
#
defmodule WebDev.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  forward "/oban", to: Ocelot.Router, private: %{repo: WebDev.Repo, oban: Oban}

  match _ do
    send_resp(conn, 404, ":(")
  end
end

defmodule WebDev.Repo do
  use Ecto.Repo, otp_app: :oban_web, adapter: Ecto.Adapters.SQLite3
end

defmodule WebDev.Migration0 do
  use Ecto.Migration

  def up, do: Oban.Migration.up()

  def down, do: Oban.Migration.down()
end

defmodule WebDev.Generator do
  @min_sleep 300
  @max_sleep 30_000

  def random_perform(min \\ @min_sleep, max \\ @max_sleep) do
    chance = :rand.uniform(100)

    cond do
      chance in 0..10 ->
        Process.sleep(min * chance)

        {:snooze, chance}

      chance in 11..25 ->
        Process.sleep(min * chance)

        raise RuntimeError, "Something went wrong!"

      true ->
        min..max
        |> Enum.random()
        |> Process.sleep()
    end
  end
end

# Worker
#
defmodule Oban.Workers.HealthChecker do
  use Oban.Worker, queue: :health, max_attempts: 3

  alias WebDev.Generator

  @impl Oban.Worker
  def perform(_job) do
    Generator.random_perform(2_000, 5_000)
  end
end

# Configuration

Application.put_env(:oban_web, WebDev.Repo, database: "./db/oban_web_dev")

oban_opts = [
  engine: Oban.Engines.Lite,
  repo: WebDev.Repo,
  queues: [
    default: 10,
    health: 3
  ],
  plugins: [
    {
      Oban.Plugins.Cron, crontab: [
        {"* * * * *", Oban.Workers.HealthChecker, tags: ~w(health monitoring)},
      ]
    }
  ]
]

Task.async(fn ->
  children = [
    {WebDev.Repo, []},
    {Oban, oban_opts},
    {Bandit, plug: WebDev.Router, scheme: :http, port: 4000},
  ]

  {:ok, _} = Supervisor.start_link(children, strategy: :one_for_one)

  Ecto.Migrator.run(WebDev.Repo, [{0, WebDev.Migration0}], :up, all: true)

  Process.sleep(:infinity)
end)
