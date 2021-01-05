defmodule Logflare.Users.Cache do
  @moduledoc """
  Cache for users.
  """

  use Logflare.Commons
  import Cachex.Spec
  @ttl 5_000

  def child_spec(_) do
    cachex_opts = [
      expiration: expiration(default: @ttl)
    ]

    %{
      id: __MODULE__,
      start: {Cachex, :start_link, [Users.Cache, cachex_opts]}
    }
  end

  def get_by(keyword), do: apply_repo_fun(__ENV__.function, [keyword])

  def get_by_and_preload(keyword), do: apply_repo_fun(__ENV__.function, [keyword])

  defp apply_repo_fun(arg1, arg2) do
    Logflare.ContextCache.apply_fun(Users, arg1, arg2)
  end
end
