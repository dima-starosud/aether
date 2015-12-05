defmodule AetherTest.CellTest do
  use ExUnit.Case

	setup_all do
		:timer.start()
	end

  test "cell sends initial waves to handler" do
		expected = {make_ref, self}
		radiate = %Aether.Radiate{to: :unique_id, wave: expected}
		Aether.Cell.start_link(:unique_id, redirect(self()), [radiate])
		assert_receive ^expected
  end

	test "cell broadcasts handler output waves" do
		[expected1, expected2] = exps =
			Enum.map([1, 2], &({make_ref, self, &1}))
		[radiate1, radiate2] =
			Enum.map(exps, &(%Aether.Radiate{to: :unique_id, wave: &1}))
		Aether.Cell.start_link(:unique_id, redirect(self(), [radiate2]), [radiate1])
		assert_receive ^expected1
		assert_receive ^expected2
		assert_receive ^expected2
	end

	test "cell changes its handler if needed" do
		radiate = %Aether.Radiate{to: :unique_id, wave: :some_dummy_wave}
		expected = {:done, ref = make_ref}
		Aether.Cell.start_link(:unique_id, counter(self(), ref, 3), [radiate])
		assert_receive ^expected
	end

	test "cells communicate to each other" do
		wave2two = make_ref
		wave2one = make_ref
		Aether.Cell.start_link(:one, redirect(self(), [%Aether.Radiate{to: :two, wave: wave2two}]))
		Aether.Cell.start_link(:two, redirect(self()), [%Aether.Radiate{to: :one, wave: wave2one}])
		assert_receive ^wave2one
		assert_receive ^wave2two
	end

	test "cell id is unique" do
		start_cell = fn ->
			Aether.Cell.start(:some_unique_id, fn _, _ -> {nil, []} end)
		end
		start_cell.()
		assert match? {:error, _}, start_cell.()
	end

  test "listener reports messages" do
    from = :unique_id
    to = :some_other_cell
    wave = make_ref
    :ok = Aether.Cell.subscribe(from)
    Aether.Cell.start_link(from, redirect(self()), [%Aether.Radiate{to: to, wave: wave}])
    assert_receive {:radiation, ^from, ^to, ^wave}
  end

	def redirect(pid, mock \\ []) do
		fn _from, _to, wave ->
			send(pid, wave)
			{nil, mock}
		end
	end

	def counter(pid, ref, n) do
		fn from, _to, wave ->
			n = n - 1
			if n == 0 do
				send(pid, {:done, ref})
				{nil, []}
			else
				{counter(pid, ref, n), [%Aether.Radiate{to: from, wave: wave}]}
			end
		end
	end
end
