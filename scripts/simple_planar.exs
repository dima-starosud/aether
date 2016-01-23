defmodule Planar.Main do

  require Logger

  alias Aether.Radiate

  @x 160
  @y 120
  @x0 div(@x, 2)
  @y0 div(@y, 2)
  @zoom "10"

  @start_timeout 10000

  defmodule Light do
    defstruct [:pos, :direct, :zoom, :color, :src]

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
      l = %Light{l | pos: {x + dx, y + dy}, src: current(l)}
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

  def data(id) do
    case id do
      {x, y} when x in [0, @x] or y in [0, @y] ->
        mirror(id)
      {_, _} ->
        nil
    end
  end

  defp mirror(id) do
    case id do
      corner when corner in [{0, 0}, {0, @y}, {@x, 0}, {@x, @y}] ->
        :reverse_mirror
      {x, _} when x in [0, @x] ->
        :vertical_mirror
      {_, y} when y in [0, @y] ->
        :horizontal_mirror
    end
  end

  def initial_light() do
    for dx <- -5..5, dy <- [-1, 1] do
      dx = 1000 * dx
      dy = 1000 * dy
      to = {@x0 + dx, @y0 + dy}
      color = 0xFFFFFF
      {to, radiation} = Light.create({@x0, @y0}, to, color) |> Light.move()
      Aether.Cell.radiate(to, radiation)
    end
  end

  def handle({x1, _}, :vertical_mirror, %Light{src: {x2, _}} = r) when x1 != x2 do
    r |> Light.mirror(:vertical) |> move_light()
  end

  def handle({_, y1}, :horizontal_mirror, %Light{src: {_, y2}} = r) when y1 != y2 do
    r |> Light.mirror(:horizontal) |> move_light()
  end

  def handle(_, :reverse_mirror, %Light{} = r) do
    r |> Light.mirror(:vertical) |> Light.mirror(:horizontal) |> move_light()
  end

  def handle(_, nil, %Light{} = r) do
    move_light(r)
  end

  def move_light(radiation) do
    {to, radiation} = Light.move(radiation)
    [%Radiate{to: to, radiation: radiation, after: 5}]
  end

  def genIds do
    for x <- 0..@x, y <- 0..@y do
      {x, y}
    end
  end


  def start do
    Logger.info("Building cells data")
    ids = genIds
    Logger.info("Subscribing...")
    Enum.each(ids, &Aether.Cell.subscribe/1)
    Logger.info("Starting cells")
    handler = &Planar.Main.handle/3
    cells = Enum.map(ids, &[&1, handler, data(&1)])
    Aether.Cell.Supervisor.start_link(cells)
    Logger.info("Spawning UI")
    putpixel = Path.join(__DIR__, "putpixel.exe")
    pp = Port.open({:spawn_executable, putpixel}, [{:cd, __DIR__}, {:args, [@zoom]}, {:line, 256}])
    true = Port.command(pp, "#{@x + 1} #{@y + 1}\n")
    Logger.info("Draw mirrors")
    ids |> Enum.each(fn id ->
      if data(id), do: send(self, {:radiation, id, nil, 0xFF0000})
    end)
    Logger.info("Triggering handlers")
    initial_light()
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


Planar.Main.start
