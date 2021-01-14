defmodule LogflareWeb.Sources.BqSchemaLive do
  use LogflareWeb, :live_component
  alias LogflareWeb.Helpers.BqSchema
  alias Logflare.Sources

  @impl true
  def render(%{source: source}) do
    {:ok, bq_schema} = Sources.get_bq_schema(source)
    BqSchema.format_bq_schema(bq_schema)
  end
end
