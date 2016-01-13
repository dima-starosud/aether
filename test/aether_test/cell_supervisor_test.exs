defmodule AetherTest.CellSupervisorTest do
  use ExUnit.Case

  test "supervise single cell" do
    id = :supervised_cell
    radiation = make_ref
    Aether.Cell.subscribe(id)
    Aether.Cell.Supervisor.start_link([[id, handler, [%Aether.Radiate{to: id, radiation: radiation}]]])
    assert_receive {:radiation, ^id, ^id, ^radiation}
    assert_receive {:radiation, ^id, ^id, ^radiation}
  end

  test "supervise two cells" do
    Aether.Cell.subscribe(:c1)
    Aether.Cell.subscribe(:c2)
    Aether.Cell.Supervisor.start_link([
      [:c1, handler, [%Aether.Radiate{to: :c2, radiation: nil}]],
      [:c2, handler, [%Aether.Radiate{to: :c1, radiation: nil}]]
    ])
    assert_receive {:radiation, :c1, :c2, nil}
    assert_receive {:radiation, :c2, :c1, nil}
    assert_receive {:radiation, :c1, :c2, nil}
    assert_receive {:radiation, :c2, :c1, nil}
  end

  def handler do
    fn _, _, _ -> exit(:boom) end
  end
end
