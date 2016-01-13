defmodule Main do

  require Logger

  alias Aether.Radiate

  defmodule Light do
    defstruct [:pos, :direct, :zoom, :color]

    def create({x0, y0}, {x1, y1}, color) do
      dx = x1 - x0
      dy = y1 - y0
      length = round(:math.sqrt(dx * dx + dy * dy))
      x0 = x0 * length
      y0 = y0 * length
      %Light{pos: {x0, y0}, direct: {dx, dy}, zoom: length, color: color}
    end

    def current(%Light{pos: {x, y}, zoom: z}) do
      {div(x, z), div(y, z)}
    end

    def color(%Light{color: color}), do: color

    def move(%Light{pos: {x, y}, direct: {dx, dy}} = l) do
      l = %Light{l | pos: {x + dx, y + dy}}
      {current(l), l}
    end

    def mirror(%Light{direct: {dx, dy}} = l, mirror) do
      case mirror do
        :horizontal ->
          dy = -dy
        :vertical ->
          dx = -dx
      end
      %Light{l | direct: {dx, dy}}
    end
  end


  defmodule Handler do
    def vertical_mirror(x, {x, _}, _, radiation) do
      handle_light(radiation)
    end

    def vertical_mirror(_, _, _, radiation) do
      radiation = Light.mirror(radiation, :vertical)
      handle_light(radiation)
    end

    def horizontal_mirror(y, {_, y}, _, radiation) do
      handle_light(radiation)
    end

    def horizontal_mirror(_, _, _, radiation) do
      radiation = Light.mirror(radiation, :horizontal)
      handle_light(radiation)
    end

    def transparent(_from, _to, radiation) do
      handle_light(radiation)
    end

    def reverse(_from, _to, radiation) do
      radiation |>
        Light.mirror(:horizontal) |>
        Light.mirror(:vertical) |>
        handle_light()
    end

    def handle_light(radiation) do
      {to, radiation} = Light.move(radiation)
      {nil, [%Radiate{to: to, radiation: radiation, after: 5}]}
    end
  end


  @x 160
  @y 120
  @x0 div(@x, 2)
  @y0 div(@y, 2)
  @zoom "10"

  @start_timeout 10000

  def start_light(from) do
    case from do
      {x, y} when x in [0, @x] or y in [0, @y] ->
        [%Radiate{radiation: 0xFF0000}]
      {@x0, @y0} ->
        for dx <- -5..5, dy <- [-1, 1] do
          dx = 1000 * dx
          dy = 1000 * dy
          to = {@x0 + dx, @y0 + dy}
          color = 0xFFFFFF
          {to, radiation} = Light.create(from, to, color) |> Light.move()
          %Radiate{to: to, radiation: radiation, after: @start_timeout}
        end
      {_, _} ->
        []
    end
  end

  def handler(id) do
    case id do
      corner when corner in [{0, 0}, {0, @y}, {@x, 0}, {@x, @y}] ->
        &Handler.reverse/3
      {x, _} when x in [0, @x] ->
        &(Handler.vertical_mirror(x, &1, &2, &3))
      {_, y} when y in [0, @y] ->
        &(Handler.horizontal_mirror(y, &1, &2, &3))
      {_, _} ->
        &Handler.transparent/3
    end
  end

  def cellsData do
    for x <- 0..@x, y <- 0..@y do
      id = {x, y}
      h = handler(id)
      w = start_light(id)
      [id, h, w]
    end
  end

  def start do
    Logger.info("Building cells data")
    cells = cellsData
    Logger.info("Subscribing")
    for c <- cells do
      Aether.Cell.subscribe(hd(c))
    end
    Logger.info("Starting cells")
    Aether.Cell.Supervisor.start_link(cells)
    Logger.info("Spawning UI")
    putpixel = Path.join(__DIR__, "putpixel.exe")
    pp = Port.open({:spawn_executable, putpixel}, [{:cd, __DIR__}, {:args, [@zoom]}, {:line, 256}])
    true = Port.command(pp, "#{@x + 1} #{@y + 1}\n")
    Logger.info("Listener loop")
    loop(pp)
  end

  def loop(pp) do
    receive do
      msg ->
        {:radiation, {x, y}, to, radiation} = msg
        {kind, color} = if to == nil do
          {"permanent", radiation}
        else
          {"temporary", Light.color(radiation)}
        end
        true = Port.command(pp, "#{kind} #{x} #{y} #{color}\n")
    end
    loop(pp)
  end

end


Main.start
