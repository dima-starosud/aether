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

	def init([id, handler, radiations]) do
		Logger.info("New cell #{inspect id} initialization with #{inspect handler}. Initial radiations: #{inspect radiations}")
		me = self()
		{^me, _} = :gproc.reg_or_locate({:n, :l, id})
		state = %Cell{id: id, handler: handler}
		schedule_radiation(id, radiations)
		{:ok, state}
	end

	defp radiate_wave(from, to, wave) do
		Logger.info("Radiation #{inspect from} ===> #{inspect wave} ===> #{inspect to}")
		for pid <- :gproc.lookup_pids({:n, :l, to}) do
			GenServer.cast(pid, {:wave, from, wave})
		end
		:ok
	end

	defp schedule_radiation(from, radiations) do
		Logger.info("Schedule radiations #{inspect radiations} from #{inspect from}")
		for r <- radiations do
			:timer.apply_after(r.after || 0, 
												 :erlang, :apply,
												 [&radiate_wave/3, [from, r.to, r.wave]])
		end
		:ok
	end

	def handle_call(_, _from, state) do
		{:noreply, state}
	end

	def handle_cast({:wave, from, wave}, state) do
		Logger.info("Received wave #{inspect wave} from #{inspect from}.")
		{handler, radiations} = state.handler.(from, wave)
		state = %Cell{state | handler: handler || state.handler}
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
