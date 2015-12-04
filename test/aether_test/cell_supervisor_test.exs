defmodule AetherTest.CellSupervisorTest do
  use ExUnit.Case

  test "supervise single cell" do
    handler = fn _, _ -> exit(:boom) end
    id = :supervised_cell
    wave = make_ref
    Aether.Cell.subscribe(id)
    Aether.Cell.Supervisor.start_link([[id, handler, [%Aether.Radiate{to: id, wave: wave}]]])
    assert_receive {:radiation, ^id, ^id, ^wave}
    assert_receive {:radiation, ^id, ^id, ^wave}
  end
end
