defmodule Aether.Cell.Supervisor do
  use Supervisor

  alias Aether.Cell

  def start_link(cells) do
    Supervisor.start_link(__MODULE__, cells)
  end

  def init(cells) do
    cells |>
      Enum.map(&worker(Cell, &1, id: hd(&1))) |>
      supervise(strategy: :one_for_one)
  end
end
