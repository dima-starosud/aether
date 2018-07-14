defmodule Planar.Simple do

  require Logger

  alias Aether.Radiate

  @zuzuz """
  @x 160
  @y 120
  @x0 div(@x, 2)
  @y0 div(@y, 2)
  @zoom "10"

  @start_timeout 10000


  defmodule Ray do
    defstruct [:pos, :direct]

    def new({x0, y0}, {x1, y1}) do
      dx = x1 - x0
      dy = y1 - y0
      length = :math.sqrt(dx * dx + dy * dy)
      dx = dx / length
      dy = dy / length
      %Ray{pos: {x0, y0}, direct: {dx, dy}}
    end

    def current(%Ray{pos: {x, y}}) do
      {round(x), round(y)}
    end

    def move(%Ray{pos: {x, y}, direct: {dx, dy}} = r) do
      r = %Ray{l | pos: {x + dx, y + dy}}
      {current(r), r}
    end

    def mirror(%Ray{direct: {dx, dy}} = r, mirror) do
      case mirror do
        :horizontal ->
          dy = -dy
        :vertical ->
          dx = -dx
        {n_dx, n_dy} ->
          Boo.zoo()
      end
      %Ray{r | direct: {dx, dy}}
    end
  end
"""


  defmodule Wall do
    defstruct [:normal]
  end


  defmodule Pebble do
    defstruct v: nil, m: 1, e: {0, 0}
  end


  defmodule Collider do
    defstruct pebbles: %{}

    defmacro remove(key) do
      quote do
        {:remove, unqoute(key)}
      end
    end
  end


  def handle(id, %Collider{} = c, %Pebble{} = p) do
    {c, key} = Collider.put(c, p)
    {c, [%Radiate{to: id, radiation: Collider.remove(key), after: @COLLISION_TIME}]}
  end

  def handle(_, %Collider{} = c, Collider.remove(key)) do
    {c, p} = Collider.remove(c, key)
    {p, to} = Pebble.move(p)
    {c, [%Radiate{to: to, radiation: p, after: @CAST_TIME}]}
  end

  def handle(_, %Wall{normal: normal}, %Pebble{v: v} = p) do
    p = Map.update!(p, :v, &(Mirror.reflect(&1, normal)))
    {p, to} = Pebble.move(p)
    {c, [%Radiate{to: to, radiation: p, after: @CAST_TIME}]}
  end


  def data(id) do
    case id do
      {x, y} when x in [0, @x] or y in [0, @y] ->
        %Wall{normal: Not.implemented()}
      {_, _} ->
        %Collider{}
    end
  end


  def throw_pebbles() do
    for dx <- -5..5, dy <- [-1, 1] do
      dx = 1000 * dx
      dy = 1000 * dy
      to = {@x0 + dx, @y0 + dy}
      {to, radiation} = Light.create({@x0, @y0}, to, color) |> Light.move()
      Aether.Cell.radiate(to, radiation)
    end
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
    handler = &Planar.Simple.handle/3
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


Planar.Simple.start
