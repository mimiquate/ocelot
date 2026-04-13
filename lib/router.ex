defmodule Ocelot.Router do
  use Plug.Router

  alias Ocelot.{HTML, Queries}

  plug(:match)
  plug(:fetch_query_params)
  plug(:put_base_path)
  plug(:dispatch)

  get "/" do
    repo = conn.private.repo
    base = conn.assigns.base

    state_counts = Queries.counts_by_state(repo)
    queue_counts = Queries.counts_by_queue(repo)

    html(conn, HTML.dashboard(state_counts, queue_counts, base))
  end

  get "/jobs" do
    repo = conn.private.repo
    base = conn.assigns.base
    params = conn.query_params

    filters = [
      state: params["state"],
      queue: params["queue"],
      worker: params["worker"]
    ]

    page = parse_page(params["page"])

    {jobs, total_pages} = Queries.list_jobs(repo, [{:page, page} | filters])

    html(conn, HTML.job_list(jobs, filters, page, total_pages, base))
  end

  get "/jobs/:id" do
    repo = conn.private.repo
    base = conn.assigns.base

    case Queries.get_job(repo, id) do
      nil -> send_resp(conn, 404, "Job not found")
      job -> html(conn, HTML.job_detail(job, base))
    end
  end

  post "/jobs/:id/retry" do
    oban = conn.private.oban
    base = conn.assigns.base

    Queries.retry_job(oban, String.to_integer(id))
    redirect(conn, "#{base}/jobs/#{id}")
  end

  post "/jobs/:id/cancel" do
    oban = conn.private.oban
    base = conn.assigns.base

    Queries.cancel_job(oban, String.to_integer(id))
    redirect(conn, "#{base}/jobs/#{id}")
  end

  post "/jobs/:id/delete" do
    repo = conn.private.repo
    base = conn.assigns.base

    Queries.delete_job(repo, String.to_integer(id))
    redirect(conn, "#{base}/jobs")
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end

  defp put_base_path(conn, _opts) do
    assign(conn, :base, "/" <> Enum.join(conn.script_name, "/"))
  end

  defp html(conn, body) do
    conn
    |> Plug.Conn.put_resp_content_type("text/html")
    |> send_resp(200, body)
  end

  defp redirect(conn, to) do
    conn
    |> Plug.Conn.put_resp_header("location", to)
    |> send_resp(302, "")
  end

  defp parse_page(nil), do: 1

  defp parse_page(s) do
    case Integer.parse(s) do
      {n, _} when n > 0 -> n
      _ -> 1
    end
  end
end
