defmodule Ocelot.Queries do
  import Ecto.Query
  alias Oban.Job

  @page_size 20

  @doc """
  Returns `{jobs, total_pages}` for the given page.

  Accepted options: `:page` (1-based, default 1).
  Results are ordered newest first (descending id), 20 per page.
  """
  def list_jobs(repo, opts \\ []) do
    page = max(Keyword.get(opts, :page, 1), 1)
    offset = (page - 1) * @page_size

    base = Job |> order_by([j], desc: j.id)

    total = repo.aggregate(base, :count)
    jobs = base |> limit(@page_size) |> offset(^offset) |> repo.all()
    total_pages = max(ceil(total / @page_size), 1)

    {jobs, total_pages}
  end

  @doc "Returns a single `Oban.Job` by id, or nil."
  def get_job(repo, id) do
    repo.get(Job, id)
  end
end
