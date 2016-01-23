defmodule AetherTest.CellTest do
  use ExUnit.Case

	setup_all do
		:timer.start()
	end

  test "cell sends initial radiations to handler" do
		expected = {make_ref, self}
		radiate = %Aether.Radiate{to: :unique_id, radiation: expected}
		Aether.Cell.start_link(:unique_id, redirect(self()), [radiate])
		assert_receive ^expected
  end

	test "cell broadcasts handler output radiations" do
		[expected1, expected2] = exps =
			Enum.map([1, 2], &({make_ref, self, &1}))
		[radiate1, radiate2] =
			Enum.map(exps, &(%Aether.Radiate{to: :unique_id, radiation: &1}))
		Aether.Cell.start_link(:unique_id, redirect(self(), [radiate2]), [radiate1])
		assert_receive ^expected1
		assert_receive ^expected2
		assert_receive ^expected2
	end

	test "cell changes its handler if needed" do
		radiate = %Aether.Radiate{to: :unique_id, radiation: :some_dummy_radiation}
		expected = {:done, ref = make_ref}
		Aether.Cell.start_link(:unique_id, counter(self(), ref, 3), [radiate])
		assert_receive ^expected
	end

	test "cells communicate to each other" do
		radiation2two = make_ref
		radiation2one = make_ref
		Aether.Cell.start_link(:one, redirect(self(), [%Aether.Radiate{to: :two, radiation: radiation2two}]))
		Aether.Cell.start_link(:two, redirect(self()), [%Aether.Radiate{to: :one, radiation: radiation2one}])
		assert_receive ^radiation2one
		assert_receive ^radiation2two
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
    radiation = make_ref
    :ok = Aether.Cell.subscribe(from)
    Aether.Cell.start_link(from, redirect(self()), [%Aether.Radiate{to: to, radiation: radiation}])
    assert_receive {:radiation, ^from, ^to, ^radiation}
  end

	def redirect(pid, mock \\ []) do
		fn _from, _to, radiation ->
			send(pid, radiation)
			{nil, mock}
		end
	end

	def counter(pid, ref, n) do
		fn from, _to, radiation ->
			n = n - 1
			if n == 0 do
				send(pid, {:done, ref})
				{nil, []}
			else
				{counter(pid, ref, n), [%Aether.Radiate{to: from, radiation: radiation}]}
			end
		end
	end
end
