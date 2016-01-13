defmodule Aether.Cell do
  use GenServer
  require Logger

  alias __MODULE__
  defstruct [:id, :handler]

  def start(id, handler, radiations \\ []) do
    GenServer.start(Cell, [id, handler, radiations])
  end

  def start_link(id, handler, radiations \\ []) do
    GenServer.start_link(Cell, [id, handler, radiations])
  end

  defmacrop listener_prop(id) do
    quote do
      {:p, :l, {Cell, :listener, unquote(id)}}
    end
  end

  defmacrop cell_name(id) do
    quote do
      {Cell, :instance, unquote(id)}
    end
  end

  def subscribe(id) do
    true = :gproc.reg(listener_prop(id))
    :ok
  end

  def init([id, handler, radiations]) do
    Logger.info("New cell #{inspect id} initialization with #{inspect handler}. Initial radiations: #{inspect radiations}")
    true = :gproc.add_local_name(cell_name(id))
    state = %Cell{id: id, handler: handler}
    schedule_radiation(id, radiations)
    {:ok, state}
  end

  defp radiate(from, to, radiation) do
    Logger.info("Radiation #{inspect from} ===> #{inspect radiation} ===> #{inspect to}")
    :gproc.send(listener_prop(from), {:radiation, from, to, radiation})
    case :gproc.lookup_local_name(cell_name(to)) do
      :undefined ->
        Logger.warn("Radiation failed. Cell #{inspect to} currently unavailable.")
      pid ->
        GenServer.cast(pid, {:radiation, from, radiation})
    end
  end

  defp schedule_radiation(from, radiations) do
    Logger.info("Schedule radiations #{inspect radiations} from #{inspect from}")
    Enum.each radiations, fn r ->
      :timer.apply_after(r.after || 0, :erlang, :apply,
        [&radiate/3, [from, r.to, r.radiation]])
    end
  end

  def handle_call(_, _from, state) do
    {:noreply, state}
  end

  def handle_cast({:radiation, from, radiation}, state) do
    Logger.info("Received radiation #{inspect radiation} from #{inspect from}.")
    {handler, radiations} = state.handler.(from, state.id, radiation)
    if handler do
      state = %Cell{state | handler: handler}
    end
    schedule_radiation(state.id, radiations)
    {:noreply, state}
  end

  def handle_cast(any, state) do
    Logger.warn("Unknown cast message: #{inspect any}")
    {:noreply, state}
  end

  def handle_info(any, state) do
    Logger.warn("Unknown info message: #{inspect any}")
    {:noreply, state}
  end
end
