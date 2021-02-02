defmodule Logflare.RepoWithCache do
  alias Logflare.{Repo, MemoryRepo}
  alias Logflare.Changefeeds
  use Logflare.DeriveVirtualDecorator
  import Logflare.EctoDerived, only: [merge_virtual: 1]

  def apply_to_repo_and_memory_repo(f, a) when is_list(a) and is_atom(f) do
    with {:repo, {:ok, repo_result}} <- {:repo, apply_repo(f, a)},
         {:memory_repo, {:ok, memory_repo_result}} <- apply_memory_repo(f, a, repo_result),
         {:memory_repo_virtual, :ok} <-
           {:memory_repo_virtual, Changefeeds.maybe_insert_virtual(memory_repo_result)} do
      {:ok, repo_result}
    else
      {:repo, err} -> err
      {:memory_repo, err} -> err
      {:memory_repo_virtual, err} -> err
    end
  end

  defp apply_repo(:insert_all = f, a) do
    [schema_or_source, entries, opts] = a
    opts = Keyword.merge(opts, returning: true)
    apply(Repo, f, [schema_or_source, entries, opts])
  end

  defp apply_repo(f, a) do
    apply(Repo, f, a)
  end

  @doc """
  Warning: possible out-of-sync.
  If, for any, reason association structs will be inserted to the memory repo
  before the struct, the association data will be nullified due to `replace_assocs_with_nils`
  """
  defp apply_memory_repo(:insert = f, [_struct_or_changeset, opts], repo_result)
       when is_struct(repo_result) do
    opts = Keyword.merge(opts, on_conflict: :replace_all, conflict_target: :id)
    struct = Changefeeds.replace_assocs_with_nils(repo_result)
    {:memory_repo, apply(MemoryRepo, f, [struct, opts])}
  end

  defp apply_memory_repo(:insert_all = f, [schema_or_source, _entries, opts], repo_result)
       when is_list(repo_result) do
    {:memory_repo,
     apply(MemoryRepo, f, [schema_or_source, params_from_structs(repo_result), opts])}
  end

  defp apply_memory_repo(f, a, _repo_result) do
    {:memory_repo, apply(MemoryRepo, f, a)}
  end

  def params_from_structs(schema_structs) when is_list(schema_structs) do
    for x <- schema_structs, do: params_from_struct(x)
  end

  def params_from_struct(schema_struct) when is_struct(schema_struct) do
    schema_struct
    |> Changefeeds.drop_assoc_fields()
    |> Map.from_struct()
    |> Map.drop([:__meta__])
  end

  def update(changeset, opts \\ []) do
    apply_to_repo_and_memory_repo(:update, [changeset, opts])
  end

  def update_all(queryable, updates, opts \\ []) do
    apply_to_repo_and_memory_repo(:update_all, [queryable, updates, opts])
  end

  def delete(struct_or_changeset, opts \\ []) do
    apply_to_repo_and_memory_repo(:delete, [struct_or_changeset, opts])
  end

  def delete!(struct_or_changeset, opts \\ []) do
    apply_to_repo_and_memory_repo(:delete!, [struct_or_changeset, opts])
  end

  def delete_all(queryable, opts \\ []) do
    apply_to_repo_and_memory_repo(:delete_all, [queryable, opts])
  end

  def insert(struct_or_changeset, opts \\ []) do
    apply_to_repo_and_memory_repo(:insert, [struct_or_changeset, opts])
  end

  def insert!(struct_or_changeset, opts \\ []) do
    apply_to_repo_and_memory_repo(:insert!, [struct_or_changeset, opts])
  end

  def insert_all(schema_or_source, entries, opts \\ []) do
    apply_to_repo_and_memory_repo(:insert_all, [schema_or_source, entries, opts])
  end

  def preload(structs_or_struct_or_nil, preloads, opts \\ []) do
    with structs_or_struct_or_nil <- MemoryRepo.preload(structs_or_struct_or_nil, preloads, opts) do
      if is_list(preloads) do
        for {k, _} <- preloads, reduce: structs_or_struct_or_nil do
          x -> merge_virtual_for_preload(x, k)
        end
      else
        merge_virtual_for_preload(structs_or_struct_or_nil, preloads)
      end
    else
      errtup -> errtup
    end
  end

  def merge_virtual_for_preload(result, preload_field) when is_atom(preload_field) do
    if is_struct(result) do
      new_assoc =
        result
        |> Map.get(preload_field)
        |> merge_virtual()

      %{result | preload_field => new_assoc}
    else
      result
    end
  end

  @decorate update_virtual_fields()
  defdelegate one(queryable), to: MemoryRepo
  defdelegate one(queryable, opts), to: MemoryRepo

  @decorate update_virtual_fields()
  defdelegate all(queryable), to: MemoryRepo
  defdelegate all(queryable, opts), to: MemoryRepo

  @decorate update_virtual_fields()
  defdelegate get_by(queryable, clauses), to: MemoryRepo
  defdelegate get_by(queryable, clauses, opts), to: MemoryRepo

  @decorate update_virtual_fields()
  defdelegate get_by!(queryable, clauses), to: MemoryRepo
  defdelegate get_by!(queryable, clauses, opts), to: MemoryRepo

  @decorate update_virtual_fields()
  defdelegate get(queryable, id), to: MemoryRepo
  defdelegate get(queryable, id, opts), to: MemoryRepo

  @decorate update_virtual_fields()
  defdelegate get!(queryable, id), to: MemoryRepo
  defdelegate get!(queryable, id, opts), to: MemoryRepo

  defdelegate aggregate(queryable, aggregate, opts), to: MemoryRepo
  defdelegate aggregate(queryable, aggregate, field, opts), to: MemoryRepo
end
