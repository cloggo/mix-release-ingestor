defmodule KV.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  # The Task module provides this functionality exactly.
  # For example, it has a start_link/1 function that receives
  # an anonymous function and executes it inside a
  # new process that will be part of a supervision tree.

  @impl true
  def init(:ok) do
    children = [
      {KV.Registry, name: KV.Registry},
      {Task.Supervisor, name: KV.RouterTasks},
      {DynamicSupervisor, name: KV.BucketSupervisor, strategy: :one_for_one},
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
