# Report for Elixir issue #11818

This is the example for a report that recompilation of path dependencies may
be inconsistent when deps are updated from the top level app.

see https://github.com/elixir-lang/elixir/issues/11818

## Usage

This report uses a modified `decompile` task from https://github.com/michalmuskala/decompile
(thanks Michal :heart:).

Use the `main` branch to go through a first run as normal:

```sh
> a √ % cd a                                                                                             
> a √ % mix deps.get                                                                                             
> a √ % iex -S mix                                                                                             
Erlang/OTP 24 [erts-12.3.1] [source] [64-bit] [smp:10:10] [ds:10:10:10] [async-threads:1]

==> b
Generated b app
Interactive Elixir (1.13.4) - press Ctrl+C to exit (type h() ENTER for help)

iex(1)> B.transaction(fn -> :ok end)

17:46:22.904 [debug] QUERY OK db=1.0ms idle=1374.6ms
begin []
 
17:46:22.906 [debug] QUERY OK db=0.1ms
commit []
{:ok, :ok}
```

Change the `ecto` dep in `b/mix.exs`:

```diff
-      {:ecto, "3.7.2"},
+      {:ecto, "~> 3.8"},
```

Update all deps, and run the same function.
It should error:

```elixir
> a ?1 % mix deps.update --all
Resolving Hex dependencies...
Dependency resolution completed:
Unchanged:
  connection 1.1.0
  db_connection 2.4.2
  decimal 2.0.0
  ecto_sqlite3 0.7.4
  elixir_make 0.6.3
  exqlite 0.11.0
  telemetry 1.1.0
Upgraded:
  ecto 3.7.2 => 3.8.3
  ecto_sql 3.7.2 => 3.8.1
* Updating ecto (Hex package)
* Updating ecto_sql (Hex package)

> a √ % iex -S mix
Erlang/OTP 24 [erts-12.3.1] [source] [64-bit] [smp:10:10] [ds:10:10:10] [async-threads:1]

==> ecto
Compiling 56 files (.ex)
Generated ecto app
==> ecto_sql
Compiling 26 files (.ex)
Generated ecto_sql app
==> ecto_sqlite3
Compiling 4 files (.ex)
warning: function query_many/4 required by behaviour Ecto.Adapters.SQL.Connection is not implemented (in module Ecto.Adapters.SQLite3.Connection)
  lib/ecto/adapters/sqlite3/connection.ex:1: Ecto.Adapters.SQLite3.Connection (module)

Generated ecto_sqlite3 app
==> b
Generated b app
==> a
Generated a app
Interactive Elixir (1.13.4) - press Ctrl+C to exit (type h() ENTER for help)

iex(1)> B.transaction fn-> :ok end
** (FunctionClauseError) no function clause matching in Ecto.Repo.Transaction.transaction/4    
    
    The following arguments were given to Ecto.Repo.Transaction.transaction/4:
    
        # 1
        B
    
        # 2 
        B
    
        # 3
        #Function<45.65746770/0 in :erl_eval.expr/5>
    
        # 4
        []
    
    Attempted function clauses (showing 3 out of 3):
    
        def transaction(_repo, _name, fun, {adapter_meta, opts}) when is_function(fun, 0)
        def transaction(repo, _name, fun, {adapter_meta, opts}) when is_function(fun, 1)
        def transaction(repo, _name, %Ecto.Multi{} = multi, {adapter_meta, opts})
    
    (ecto 3.8.3) lib/ecto/repo/transaction.ex:5: Ecto.Repo.Transaction.transaction/4
```

Decompile the `B` beam file and inspect the `transaction/1` function:

```sh
> a √ % mix decompile _build/dev/lib/b/ebin/Elixir.B.beam --to expanded
> a √ % grep -A 7 "def transaction(fun" Elixir.B.ex
  def transaction(fun_or_multi, opts) do
    Ecto.Repo.Transaction.transaction(
      B,
      get_dynamic_repo(),
      fun_or_multi,
      with_default_options(:transaction, opts)
    )
  end
```

Clean the build, rebuild, recompile:

```sh
> a √ % rm -rf _build
> a √ % mix compile 
```

Decompile and inspect again. The definition will be different even though
the `ecto` dependency was not changed signifying that it was not recompiled
previously when `ecto` was updated:

```sh
> a √ % mix decompile _build/dev/lib/b/ebin/Elixir.B.beam --to expanded
> a √ % grep -A 7 "def transaction(fun" Elixir.B.ex                    
  def transaction(fun_or_multi, opts) do
    repo = get_dynamic_repo()

    Ecto.Repo.Transaction.transaction(
      B,
      repo,
      fun_or_multi,
      Ecto.Repo.Supervisor.tuplet(repo, prepare_opts(:transaction, opts))
```

## Success case

I initially tried to separate these steps by a github branch, `update-dep`.
However, if you do these steps, recompilation works as expected:

1. Run everything in `main` branch
2. `git checkout update-dep`
3. `mix deps.update --all`
4. `iex -S mix`
5. `B.transaction(fn -> :ok end)`

¯\\_(ツ)_/¯ 
