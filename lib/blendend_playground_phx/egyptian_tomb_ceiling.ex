# Adopted from https://openprocessing.org/sketch/2349902

use Blendend.Draw
alias Blendend.Path
alias BlendendPlaygroundPhx.Curves

defmodule BlendendPlaygroundPhx.Demos.EgyptianTombCeiling do
  @doc """
  Draws a flower centered at `{x, y}` with diameter `d` and fill color `c`.

  Generates a ring of 22 Catmull-Rom control points (four per petal), converts each
  segment to cubic Beziers.
  """
  def flower(x, y, d, c \\ rgb(200, 120, 200)) do
    r = d * 0.5
    two_pi = 2 * :math.pi()
    base_angle = two_pi / 22.0

    # Build ring of points 
    pts =
      0.0
      |> Stream.iterate(&(&1 + base_angle))
      |> Stream.take_while(&(&1 < two_pi))
      |> Stream.flat_map(fn a ->
        [
          vec(a + two_pi / 96, r / 4),
          vec(a - two_pi / 48, r * 0.8),
          vec(a + two_pi / 48, r * 0.8),
          vec(a - two_pi / 96, r / 4)
        ]
      end)
      |> Enum.to_list()

    Path.new!()
    |> Curves.curve_vertices!(pts, closed?: true)
    |> Path.translate!(x, y)
    |> fill_path(fill: c)
  end

  defp vec(angle, radius) do
    {radius * :math.sin(angle), radius * :math.cos(angle)}
  end
end
