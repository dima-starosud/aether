defmodule AetherTest.CellTest do
  use ExUnit.Case

	setup_all do
		:timer.start()
	end

  test "cell sends initial waves to handler" do
		expected = %Aether.Wave{meta: :test, data: self()}
		{:ok, _pid} = Aether.Cell.start_link(:unique_id, redirect(self()), [expected])
		assert_receive ^expected
  end

	test "cell broadcasts handler output waves" do
		[expected1, expected2] = Enum.map([1, 2], &(%Aether.Wave{meta: :test, data: {self(), &1}}))
		radiate = %Aether.Cell.Radiate{to: :unique_id, wave: expected2}
		{:ok, _pid} = Aether.Cell.start_link(:unique_id, redirect(self(), [radiate]), [expected1])
		assert_receive ^expected1
		assert_receive ^expected2
	end

	def redirect(pid, mock \\ []) do
		fn _from, wave ->
			send(pid, wave)
			{nil, mock}
		end
	end
end
