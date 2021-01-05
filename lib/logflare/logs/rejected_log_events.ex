defmodule Logflare.Logs.RejectedLogEvents do
  @moduledoc """
  Handles and caches LogEvents that failed validation. To genereate a rejected log:
  `Logger.info("should be rejected", users_1: [%{id: "1"}, %{id: 1}] )`

  or

  ```
  curl -X "POST" "http://localhost:4000/logs/cloudflare" \
    -H 'Content-Type: application/json' \
    -H 'X-API-KEY: EdR8jNi258ji' \
    -d $'{
      "metadata": {
        "users": [
          {"id": "1"},
          {"id": 1}
        ]
      },
      "log_entry": "should be rejected",
      "source": "09f5db03-ac00-44fa-80b5-26a531e09524"
    }'
  ```
  """
  use Logflare.Commons
  @cache __MODULE__

  def child_spec(_) do
    %{id: @cache, start: {Cachex, :start_link, [@cache, []]}}
  end

  @spec get_by_user(Logflare.User.t()) :: %{atom => list(LE.t())}
  def get_by_user(%User{sources: sources}) do
    for source <- sources, into: Map.new() do
      {source.token, get_by_source(source)}
    end
  end

  @spec get_by_source(Source.t()) :: list(LE.t())
  def get_by_source(%Source{token: token}) do
    get!(token).log_events
    |> Enum.reverse()
  end

  def count(%Source{} = s) do
    s.token
    |> get!()
    |> Map.get(:count, 0)
  end

  def delete_by_source(%Source{token: token}) do
    {:ok, true} = Cachex.del(@cache, token)
  end

  @doc """
  Expected to be called only in Logs context
  """
  @spec ingest(LE.t()) :: :ok
  def ingest(%LE{source: %Source{token: token}, valid?: false} = le) do
    Cachex.get_and_update!(@cache, token, fn
      %{log_events: les, count: c} ->
        les =
          [le | les]
          |> List.flatten()
          |> Enum.take(100)

        %{log_events: les, count: c + 1}

      _ ->
        %{log_events: [le], count: 1}
    end)

    :ok
  end

  @spec get!(atom) :: %{log_events: list(LE.t()), count: non_neg_integer}
  defp get!(key) do
    {:ok, val} = Cachex.get(@cache, key)
    val || %{log_events: [], count: 0}
  end
end
