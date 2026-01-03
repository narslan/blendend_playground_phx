# PostScript tiger workbench: decodes Blend2D tiger.
alias BlendendPlaygroundPhx.Demos.{Tiger, TigerData}

draw TigerData.width(), TigerData.height() do
  clear(fill: rgb(240, 240, 240))

  segments = Tiger.decode_paths()

  Enum.each(segments, fn seg ->
    if seg.fill? do
      fill_rule(seg.fill_rule)
      {r, g, b} = seg.fill_color
      fill_path(seg.path, fill: rgb(r, g, b))
    end

    if seg.stroke? do
      {r, g, b} = seg.stroke_color

      stroke_path(seg.path,
        stroke: rgb(r, g, b),
        stroke_width: seg.stroke_opts.stroke_width,
        stroke_cap: seg.stroke_opts.stroke_cap,
        stroke_join: seg.stroke_opts.stroke_join,
        stroke_miter_limit: seg.stroke_opts.stroke_miter_limit
      )
    end
  end)
end
