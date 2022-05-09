# Elixir Review

## Erlang/OTP
* Erlang is a functional programming language
* OTP (Open Telecom Platform) is a large collection of libraries for Erlang to do everything from compiling ASN.1 to providing a WWW server
* BEAM, the virtual machine that executes user code in the Erlang Runtime System (ERTS)
* The Erlang Runtime System Application, ERTS, contains functionality necessary to run the Erlang system.

### Agents
* Agents are simple wrappers around state

```elixir
iex> {:ok, agent} = Agent.start_link fn -> [] end
{:ok, #PID<0.57.0>}
iex> Agent.update(agent, fn list -> ["eggs" | list] end)
:ok
iex> Agent.get(agent, fn list -> list end)
["eggs"]
iex> Agent.stop(agent)
:ok
```

### GenServer
* GenServer is a registry process that can monitor the bucket processes 
* Calls are synchronous and the server must send a response back to such requests. While the server computes the response, the client is waiting. Casts are asynchronous: the server won’t send a response back and therefore the client won’t wait for one. Both requests are messages sent to the server, and will be handled in sequence. 

```elixir

defmodule KV.Registry do
  use GenServer

  ## Missing Client API - will add this later

  ## Defining GenServer Callbacks

  @impl true
  def init(:ok) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:lookup, name}, _from, names) do
    {:reply, Map.fetch(names, name), names}
  end

  @impl true
  def handle_cast({:create, name}, names) do
    if Map.has_key?(names, name) do
      {:noreply, names}
    else
      {:ok, bucket} = KV.Bucket.start_link([])
      {:noreply, Map.put(names, name, bucket)}
    end
  end
end
```

```elixir
iex> {:ok, registry} = GenServer.start_link(KV.Registry, :ok)
{:ok, #PID<0.136.0>}
iex> GenServer.cast(registry, {:create, "shopping"})
:ok
iex> {:ok, bk} = GenServer.call(registry, {:lookup, "shopping"})
{:ok, #PID<0.174.0>}
```

### Supervisor

*  A Supervisor is a process that supervises other processes and restarts them whenever they crash.
* strategy :one_for_one means that if a child dies, it will be the only one restarted. 

* The root supervisor is the one started by application callback.  Our supervisor could have other children, and some of these children could be their own supervisors with their own children, leading to the so-called supervision trees

```elixir
defmodule KV.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      KV.Registry
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
```

* Dynamic supervisor

```elixir
 def init(:ok) do
    children = [
      {KV.Registry, name: KV.Registry},
      {DynamicSupervisor, name: KV.BucketSupervisor, strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
```


### ETS (Erlang Term Storage)
* how to use it as a cache mechanism


### Umbrella Project
* Accessing internal dependencies


### Requirements

I’ve been planning to make it into something config-driven, where you just point it at a config file that specifies the same things the CLI args for the mix server task do: the set of jobs that should be run for each network but with much more opportunity for tuning

Right now there’s a lot of config that’s burned into the various network-definition files (lib/ingestor/network/*.ex) despite it being specific to a particular RPC endpoint connection (i.e. the tuning would be different if we used a local node vs. if we used a public RPC provider) and those things would more properly live in a deploy-time config spec
that could get passed in as a k8s ConfigMap, mounted as a file, and then the ingestor would discover that file at a known path (scout already does something similar with its containerization; there’s a config file that k8s writes to /app/release.properties that scout picks up on boot)
