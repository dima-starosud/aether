defmodule Aether.Cell do
	use GenServer
	require Logger

	alias __MODULE__
	defstruct [:id, :handler]

	defmodule Radiate do
		defstruct [:to, :after, :wave]
	end

	def init([id, handler, waves]) do
		me = self()
		{^me, _} = :gproc.reg_or_locate({:n, :l, id})
		state = %Cell{id: id, handler: wrap_handler(handler)}
		radiate(id, waves)
		{:ok, state}
	end

	def init([id, handler]) do
		init([id, handler, []])
	end

	defp wrap_handler({m, f, a}), do: &apply(m, f, a ++ [&1, &2])
	defp wrap_handler(f) when is_function(f, 2), do: f

	defp do_radiate(from, to, wave) do
		for pid <- :gproc.lookup_pids({:n, :l, to}) do
			GenServer.cast(pid, {:wave, from, wave})
		end
	end

	defp radiate(from, waves) do
		for wave <- waves do
			:timer.apply_after(wave.after, :erlang, :apply, [&do_radiate/3, [from, wave.to, wave.wave]])
		end
	end

	def handle_call(_, _from, state) do
		{:noreply, state}
	end

	def handle_cast({:wave, from, wave}, state) do
		{handler, waves} = state.handler.(from, wave)
		state = %Cell{state | handler: wrap_handler(handler || state.handler)}
		radiate(state.id, waves)
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
