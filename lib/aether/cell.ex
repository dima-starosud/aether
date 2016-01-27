defmodule Aether.Cell do
  use GenServer
  require Logger

  alias Aether.Radiate

  alias __MODULE__
  defstruct [:id, :handler, :data]

  def start(id, handler, data \\ nil) do
    GenServer.start(Cell, [id, handler, data])
  end

  def start_link(id, handler, data \\ nil) do
    GenServer.start_link(Cell, [id, handler, data])
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

  def init([id, handler, data]) do
    Logger.info("New cell #{inspect id} initialization with #{inspect handler}.")
    true = :gproc.add_local_name(cell_name(id))
    {:ok, %Cell{id: id, handler: handler, data: data}}
  end

  defp handle_radiation(%Cell{id: id, handler: handler, data: data} = state, radiation) do
    process_handler_output(state, handler.(id, data, radiation))
  end

  defp process_handler_output(state, {radiations, data}) do
    schedule_radiations(state.id, radiations)
    %Cell{state | data: data}
  end

  defp process_handler_output(state, radiations) when is_list(radiations) do
    schedule_radiations(state.id, radiations)
    state
  end

  def radiate(to, radiation) do
    pid = :gproc.lookup_local_name(cell_name(to))
    if is_pid(pid) do
      GenServer.cast(pid, {:radiation, radiation})
    end
    :ok
  end

  defp radiate(from, to, radiation) do
    :gproc.send(listener_prop(from), {:radiation, from, to, radiation})
    radiate(to, radiation)
  end

  defp schedule_radiations(from, radiations) do
    Enum.each radiations, fn %Radiate{to: t, radiation: r, after: a} ->
      :timer.apply_after(a || 5, :erlang, :apply, [&radiate/3, [from, t, r]])
    end
  end

  def handle_cast({:radiation, radiation}, state) do
    {:noreply, handle_radiation(state, radiation)}
  end

  def handle_cast(any, state) do
    Logger.warn("Unknown cast message: #{inspect any}")
    {:noreply, state}
  end

  def handle_call(_, _from, state) do
    {:noreply, state}
  end

  def handle_info(any, state) do
    Logger.warn("Unknown info message: #{inspect any}")
    {:noreply, state}
  end
end
