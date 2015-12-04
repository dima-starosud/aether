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

  test "supervise two cells" do
    handler = fn _, _ -> exit(:boom) end
    Aether.Cell.subscribe(:c1)
    Aether.Cell.subscribe(:c2)
    Aether.Cell.Supervisor.start_link([
      [:c1, handler, [%Aether.Radiate{to: :c2, wave: nil}]],
      [:c2, handler, [%Aether.Radiate{to: :c1, wave: nil}]]
    ])
    assert_receive {:radiation, :c1, :c2, nil}
    assert_receive {:radiation, :c2, :c1, nil}
    assert_receive {:radiation, :c1, :c2, nil}
    assert_receive {:radiation, :c2, :c1, nil}
  end
end
