defmodule Ocelot.Queries do
  import Ecto.Query
  alias Oban.Job

  @states ~w(available scheduled executing retryable completed cancelled discarded)
  @page_size 20

  @doc "Returns a map of job counts keyed by state string, with zero-fill for missing states."
  def counts_by_state(repo) do
    defaults = Map.new(@states, &{&1, 0})

    from(j in Job, select: {j.state, count(j.id)}, group_by: j.state)
    |> repo.all()
    |> Map.new()
    |> then(&Map.merge(defaults, &1))
  end

  @doc "Returns a list of maps with :queue and :total keys, ordered by queue name."
  def counts_by_queue(repo) do
    from(j in Job,
      select: %{queue: j.queue, total: count(j.id)},
      group_by: j.queue,
      order_by: j.queue
    )
    |> repo.all()
  end

  @doc """
  Returns `{jobs, total_pages}` for the given filter options.

  Accepted options: `:state`, `:queue`, `:worker`, `:page` (1-based, default 1).
  Results are ordered newest first (descending id), 20 per page.
  """
  def list_jobs(repo, opts \\ []) do
    page = max(Keyword.get(opts, :page, 1), 1)
    offset = (page - 1) * @page_size

    base =
      Job
      |> order_by([j], desc: j.id)
      |> maybe_filter(:state, opts[:state])
      |> maybe_filter(:queue, opts[:queue])
      |> maybe_filter(:worker, opts[:worker])

    total = repo.aggregate(base, :count)
    jobs = base |> limit(@page_size) |> offset(^offset) |> repo.all()
    total_pages = max(ceil(total / @page_size), 1)

    {jobs, total_pages}
  end

  @doc "Returns a single `Oban.Job` by id, or nil."
  def get_job(repo, id) do
    repo.get(Job, id)
  end

  @doc "Retries a job via `Oban.retry_job/2`."
  def retry_job(oban, id) do
    Oban.retry_job(oban, id)
  end

  @doc "Cancels a job via `Oban.cancel_job/2`."
  def cancel_job(oban, id) do
    Oban.cancel_job(oban, id)
  end

  @doc "Deletes a job directly from the database."
  def delete_job(repo, id) do
    from(j in Job, where: j.id == ^id) |> repo.delete_all()
  end

  defp maybe_filter(query, _field, nil), do: query
  defp maybe_filter(query, :state, value), do: where(query, [j], j.state == ^value)
  defp maybe_filter(query, :queue, value), do: where(query, [j], j.queue == ^value)
  defp maybe_filter(query, :worker, value), do: where(query, [j], j.worker == ^value)
end
