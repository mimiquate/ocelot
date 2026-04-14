defmodule Ocelot.HTML do
  @moduledoc false

  require EEx

  @templates Path.join(__DIR__, "templates")

  EEx.function_from_file(:def, :layout, Path.join(@templates, "layout.html.eex"), [
    :title,
    :inner
  ])

  EEx.function_from_file(:defp, :job_list_inner, Path.join(@templates, "job_list.html.eex"), [
    :jobs,
    :page,
    :total_pages,
    :base
  ])

  EEx.function_from_file(:defp, :job_detail_inner, Path.join(@templates, "job_detail.html.eex"), [
    :job,
    :base
  ])

  def job_list(jobs, page, total_pages, base) do
    inner = job_list_inner(jobs, page, total_pages, base)
    layout("Jobs", inner)
  end

  def job_detail(job, base) do
    inner = job_detail_inner(job, base)
    layout("Job ##{job.id}", inner)
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp state_classes("available"), do: "bg-emerald-100 text-emerald-800"
  defp state_classes("scheduled"), do: "bg-amber-100 text-amber-800"
  defp state_classes("executing"), do: "bg-blue-100 text-blue-800"
  defp state_classes("retryable"), do: "bg-orange-100 text-orange-800"
  defp state_classes("completed"), do: "bg-gray-100 text-gray-600"
  defp state_classes("cancelled"), do: "bg-gray-100 text-gray-600"
  defp state_classes("discarded"), do: "bg-red-100 text-red-800"
  defp state_classes(_), do: "bg-gray-100 text-gray-600"

  defp format_dt(nil), do: "—"
  defp format_dt(%DateTime{} = dt), do: Calendar.strftime(dt, "%Y-%m-%d %H:%M:%S UTC")

end
