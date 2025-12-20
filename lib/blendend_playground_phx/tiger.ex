defmodule BlendendPlaygroundPhx.Demos.Tiger do
  @moduledoc """
  Minimal loader for the Blend2D tiger demo data.

  Uses the commands/points encoded in `TigerData` to build Blendend paths.
  Does not perform path `shrink/0` or any post-translate; kept simple for experimentation.
  """
  alias Blendend.Path
  alias BlendendPlaygroundPhx.Demos.TigerData

  def decode_paths do
    cmds = String.to_charlist(TigerData.commands())
    pts = TigerData.points()
    height = TigerData.height()
    {paths, _ci, _pi} = parse_paths(cmds, pts, height, 0, 0, [])
    Enum.reverse(paths)
  end

  defp parse_paths(cmds, _pts, _h, ci, pi, acc) when ci >= length(cmds),
    do: {acc, ci, pi}

  defp parse_paths(cmds, pts, h, ci, pi, acc) do
    fill_flag = Enum.at(cmds, ci)
    ci = ci + 1
    stroke_flag = Enum.at(cmds, ci)
    ci = ci + 1
    cap_flag = Enum.at(cmds, ci)
    ci = ci + 1
    join_flag = Enum.at(cmds, ci)
    ci = ci + 1

    miter = Enum.at(pts, pi)
    pi = pi + 1
    stroke_width = Enum.at(pts, pi)
    pi = pi + 1

    sc_r = trunc(Enum.at(pts, pi + 0) * 255)
    sc_g = trunc(Enum.at(pts, pi + 1) * 255)
    sc_b = trunc(Enum.at(pts, pi + 2) * 255)
    fc_r = trunc(Enum.at(pts, pi + 3) * 255)
    fc_g = trunc(Enum.at(pts, pi + 4) * 255)
    fc_b = trunc(Enum.at(pts, pi + 5) * 255)
    pi = pi + 6

    count = trunc(Enum.at(pts, pi))
    pi = pi + 1

    {path, ci_after, pi_after} =
      build_path(count, cmds, pts, h, ci, pi, Path.new!())

    stroke_opts = %{
      stroke_width: stroke_width,
      stroke_cap: cap_atom(cap_flag),
      stroke_join: join_atom(join_flag),
      stroke_miter_limit: miter
    }

    seg = %{
      path: path,
      fill?: fill_flag(fill_flag),
      fill_rule: fill_rule(fill_flag),
      stroke?: stroke_flag == ?S,
      stroke_opts: stroke_opts,
      stroke_color: {sc_r, sc_g, sc_b},
      fill_color: {fc_r, fc_g, fc_b}
    }

    parse_paths(cmds, pts, h, ci_after, pi_after, [seg | acc])
  end

  defp build_path(0, _cmds, _pts, _h, ci, pi, path), do: {path, ci, pi}

  defp build_path(n, cmds, pts, h, ci, pi, path) do
    case Enum.at(cmds, ci) do
      ?M ->
        x = Enum.at(pts, pi)
        y = h - Enum.at(pts, pi + 1)
        path = Path.move_to!(path, x, y)
        build_path(n - 1, cmds, pts, h, ci + 1, pi + 2, path)

      ?L ->
        x = Enum.at(pts, pi)
        y = h - Enum.at(pts, pi + 1)
        path = Path.line_to!(path, x, y)
        build_path(n - 1, cmds, pts, h, ci + 1, pi + 2, path)

      ?C ->
        x1 = Enum.at(pts, pi)
        y1 = h - Enum.at(pts, pi + 1)
        x2 = Enum.at(pts, pi + 2)
        y2 = h - Enum.at(pts, pi + 3)
        x3 = Enum.at(pts, pi + 4)
        y3 = h - Enum.at(pts, pi + 5)
        path = Path.cubic_to!(path, x1, y1, x2, y2, x3, y3)
        build_path(n - 1, cmds, pts, h, ci + 1, pi + 6, path)

      ?E ->
        path = Path.close!(path)
        build_path(n - 1, cmds, pts, h, ci + 1, pi, path)
    end
  end

  defp cap_atom(?B), do: :butt
  defp cap_atom(?R), do: :round
  defp cap_atom(?S), do: :square
  defp cap_atom(_), do: :butt

  defp join_atom(?M), do: :miter_bevel
  defp join_atom(?R), do: :round
  defp join_atom(?B), do: :bevel
  defp join_atom(_), do: :miter_bevel

  defp fill_flag(?N), do: false
  defp fill_flag(_), do: true

  defp fill_rule(?E), do: :even_odd
  defp fill_rule(_), do: :non_zero
end
