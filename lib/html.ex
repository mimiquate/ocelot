defmodule Ocelot.HTML do
  @moduledoc false

  require EEx

  @state_order ~w(executing available scheduled retryable discarded cancelled completed)

  @templates Path.join(__DIR__, "templates")

  EEx.function_from_file(:def, :layout, Path.join(@templates, "layout.html.eex"), [:title, :base, :inner])

  EEx.function_from_file(:defp, :dashboard_inner, Path.join(@templates, "dashboard.html.eex"), [:state_counts, :queue_counts, :base, :state_order])

  EEx.function_from_file(:defp, :job_list_inner, Path.join(@templates, "job_list.html.eex"), [:jobs, :filters, :page, :total_pages, :base])

  EEx.function_from_file(:defp, :job_detail_inner, Path.join(@templates, "job_detail.html.eex"), [:job, :base])


  def dashboard(state_counts, queue_counts, base) do
    inner = dashboard_inner(state_counts, queue_counts, base, @state_order)
    layout("Dashboard", base, inner)
  end


  def job_list(jobs, filters, page, total_pages, base) do
    inner = job_list_inner(jobs, filters, page, total_pages, base)
    layout("Jobs", base, inner)
  end

  def job_detail(job, base) do
    inner = job_detail_inner(job, base)
    layout("Job ##{job.id}", base, inner)
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp state_classes("available"),  do: "bg-emerald-100 text-emerald-800"
  defp state_classes("scheduled"),  do: "bg-amber-100 text-amber-800"
  defp state_classes("executing"),  do: "bg-blue-100 text-blue-800"
  defp state_classes("retryable"),  do: "bg-orange-100 text-orange-800"
  defp state_classes("completed"),  do: "bg-gray-100 text-gray-600"
  defp state_classes("cancelled"),  do: "bg-gray-100 text-gray-600"
  defp state_classes("discarded"),  do: "bg-red-100 text-red-800"
  defp state_classes(_),            do: "bg-gray-100 text-gray-600"

  defp format_dt(nil), do: "—"
  defp format_dt(%DateTime{} = dt), do: Calendar.strftime(dt, "%Y-%m-%d %H:%M:%S UTC")

  defp page_link(base, filters, page) do
    params =
      filters
      |> Enum.reject(fn {_k, v} -> is_nil(v) or v == "" end)
      |> Keyword.put(:page, page)
      |> URI.encode_query()

    "#{base}/jobs?#{params}"
  end
end
