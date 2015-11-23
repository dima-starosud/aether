defmodule AetherTest.CellTest do
  use ExUnit.Case

  test "cell sends initial waves to handler" do
		:timer.start()
		expected = %Aether.Wave{meta: :test, data: self()}
		{:ok, _pid} = Aether.Cell.start_link(:unique_id, redirect(self()), [expected])
    assert_receive expected
  end

	def redirect(pid) do
		fn _from, wave ->
			IO.inspect {:received, wave}
			send(pid, wave)
			{nil, []}
		end
	end
end
