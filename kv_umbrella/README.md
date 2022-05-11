# KvUmbrella

**TODO: Add description**
```elixir
  @doc false
  def run(args) do
    job_names =
      Ingestor.Runner.job_specs([:dummy_network], :dummy_repo)
      |> Enum.map(fn {_, job} ->
        Keyword.fetch!(job, :job_name)
      end)
      |> MapSet.new()

# job_names =      MapSet<[:batch_blocks, :batch_blocks_catchup, :batch_trace_events, :contract_currencies, :contract_programs, :dedup_blocks, :echo, :historical_contract_balances, :historical_native_balances, :legacy_batch_blocks, :legacy_batch_blocks_catchup, :legacy_fixup_batch_overrun, :stream_reports, :streaming_blocks, :streaming_blocks_catchup, :streaming_blocks_gaps, :streaming_blocks_gaps_historical, :streaming_blocks_gaps_periodic, :streaming_blocks_orphans, :trim_streams, :truncate_streaming_blocks]>

    job_enable_switches = Enum.map(job_names, &{&1, :boolean})

# job_enable_switches = [batch_blocks: :boolean, batch_blocks_catchup: :boolean, batch_trace_events: :boolean, contract_currencies: :boolean, contract_programs: :boolean, dedup_blocks: :boolean, echo: :boolean, historical_contract_balances: :boolean, historical_native_balances: :boolean, legacy_batch_blocks: :boolean, legacy_batch_blocks_catchup: :boolean, legacy_fixup_batch_overrun: :boolean, stream_reports: :boolean, streaming_blocks: :boolean, streaming_blocks_catchup: :boolean, streaming_blocks_gaps: :boolean, streaming_blocks_gaps_historical: :boolean, streaming_blocks_gaps_periodic: :boolean, streaming_blocks_orphans: :boolean, trim_streams: :boolean, truncate_streaming_blocks: :boolean]

# job_enable_switches ++ @base_switches = [:standard_io, [batch_blocks: :boolean, batch_blocks_catchup: :boolean, batch_trace_events: :boolean, contract_currencies: :boolean, contract_programs: :boolean, dedup_blocks: :boolean, echo: :boolean, historical_contract_balances: :boolean, historical_native_balances: :boolean, legacy_batch_blocks: :boolean, legacy_batch_blocks_catchup: :boolean, legacy_fixup_batch_overrun: :boolean, stream_reports: :boolean, streaming_blocks: :boolean, streaming_blocks_catchup: :boolean, streaming_blocks_gaps: :boolean, streaming_blocks_gaps_historical: :boolean, streaming_blocks_gaps_periodic: :boolean, streaming_blocks_orphans: :boolean, trim_streams: :boolean, truncate_streaming_blocks: :boolean, networks: :string, exclude_networks: :string, repo: :string]


    {opts, pos_args, []} = OptionParser.parse(args, strict: job_enable_switches ++ @base_switches)

    enabled_job_names =
      Enum.flat_map(opts, fn
        {opt, true} -> [opt]
        _ -> []
      end)
      |> Enum.into(MapSet.new())
      |> MapSet.intersection(job_names)

    enabled_networks_spec =
      case Keyword.fetch(opts, :networks) do
        {:ok, "all"} ->
          :all

        {:ok, enabled_mod_names_str} ->
          case String.split(enabled_mod_names_str, ",", trim: true) do
            [] ->
              :all

            enabled_mod_names ->
              {:list, enabled_mod_names}
          end

        :error ->
          :all
      end

    disabled_networks_spec =
      case Keyword.fetch(opts, :exclude_networks) do
        {:ok, disabled_mod_names_str} ->
          String.split(disabled_mod_names_str, ",", trim: true)

        :error ->
          []
      end

    # return the list of module of the network from:
    # Ingestor.Network.<network_spec>
    networks = Ingestor.Runner.resolve_network_modspec(enabled_networks_spec, disabled_networks_spec)

    repo_mod =
      case Keyword.fetch(opts, :repo) do
        {:ok, repo_mod_name} ->
          Module.concat(Elixir, repo_mod_name)

        :error ->
          Ingestor.Repo
      end

    case {MapSet.size(enabled_job_names), length(networks)} do
      {n, m} when n > 0 and m > 0 ->
        enabled_jobs =
          Ingestor.Runner.job_specs(networks, repo_mod)
          |> Enum.filter(fn {_, job_params} ->
            MapSet.member?(enabled_job_names, Keyword.fetch!(job_params, :job_name))
          end)

        run_with_jobs(networks, enabled_jobs, pos_args)

      {0, _} ->
        Mix.shell().error("Cannot start a server without any jobs for it to do; aborting.")

      {_, 0} ->
        Mix.shell().error("Cannot start a server detached from any networks; aborting.")
    end
  end

  def run_with_jobs(networks, enabled_job_specs, run_args) do
    # run_args() => "--no-halt"
    Mix.Tasks.Run.run(run_args() ++ run_args)
    networks = Enum.filter(networks, & &1.configured?)

    Logger.info(
      IO.ANSI.format([
        "running on networks: ",
        Enum.map(networks, fn network ->
          [:bright, network.description(), :reset]
        end)
        |> Enum.intersperse(", ")
      ])
    )

    sync_jobs =
      Enum.filter(enabled_job_specs, fn {_, job} -> Keyword.get(job, :start_sync) end)
      |> Enum.group_by(fn {_job_name, job} ->
        get_in(job, [:start_sync, :order]) || 0
      end)
      |> Enum.map(fn {step_id, jobs} ->
        {step_id, Enum.sort(jobs)}
      end)
      |> Enum.sort()

    scheduled_jobs = Enum.filter(enabled_job_specs, fn {_, job} -> Keyword.get(job, :schedule) end)

    start_async_jobs = Enum.filter(enabled_job_specs, fn {_, job} -> Keyword.get(job, :start_async) end)


    for {_, step_jobs} <- sync_jobs do
      Ingestor.Runner.run_sync_job(step_jobs)
    end
```
