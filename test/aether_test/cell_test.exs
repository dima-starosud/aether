defmodule AetherTest.CellTest do
  use ExUnit.Case

	setup_all do
		:timer.start()
	end

  test "cell sends initial waves to handler" do
		expected = {make_ref, self}
		radiate = %Aether.Radiate{to: :unique_id, wave: expected}
		{:ok, pid} = Aether.Cell.start_link(:unique_id, redirect(self()), [radiate])
		on_exit killer(pid)
		assert_receive ^expected
  end

	test "cell broadcasts handler output waves" do
		[expected1, expected2] = exps =
			Enum.map([1, 2], &({make_ref, self, &1}))
		[radiate1, radiate2] =
			Enum.map(exps, &(%Aether.Radiate{to: :unique_id, wave: &1}))
		{:ok, pid} = Aether.Cell.start_link(:unique_id, redirect(self(), [radiate2]), [radiate1])
		on_exit killer(pid)
		assert_receive ^expected1
		assert_receive ^expected2
		assert_receive ^expected2
	end

	def redirect(pid, mock \\ []) do
		fn _from, wave ->
			send(pid, wave)
			{nil, mock}
		end
	end

	def killer(pid) do
		fn ->
			:erlang.exit(pid, :kill)
			IO.inspect {:killed, pid}
		end
	end
end
