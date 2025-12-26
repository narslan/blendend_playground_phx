draw 420, 240 do
  clear(fill: rgb(242, 230, 216))

  p =
    path do
      add_rect(0, 0, 400, 200)
    end

  watercolor_fill_path(p,
    fill: hsv(210, 1, 0.8),
    alpha: 0.6,
    bleed_sigma: 16.0,
    granulation: 0.5,
    noise_scale: 0.1,
    seed: 123,
    resolution: 0.6
  )

  grad = Blendend.Style.Gradient.linear!(0, 0, 0, 300)
  :ok = Blendend.Style.Gradient.add_stop(grad, 0.0, hsv(30, 1, 0.9))
  :ok = Blendend.Style.Gradient.add_stop(grad, 1.0, hsv(210, 1, 0.8))

  watercolor_fill_path(p,
    fill: grad,
    alpha: 0.1,
    comp_op: :color_burn,
    seed: 123,
    bleed_sigma: 10.0,
    granulation: 0.15
  )
end
