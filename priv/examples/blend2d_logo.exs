# The logo of blend2d. Shows overlapping radial and linear gradients to recreate the icon colors.
draw 600, 600 do
  grad =
    radial_gradient 90, 90, 90, 90, 90, 0 do
      add_stop(0.0, rgb(0xFF, 0xFF, 0xFF))
      add_stop(1.0, rgb(0xFF, 0x6F, 0x3F))
    end

  grad2 =
    linear_gradient 97, 97, 235, 235 do
      add_stop(0.0, rgb(0xFF, 0xFF, 0xFF))
      add_stop(1.0, rgb(0x3F, 0x9F, 0xFF))
    end

  circle(90, 90, 87, fill: grad)
  
  round_rect(97, 97, 150, 150, 20, 20, fill: grad2, comp_op: :difference)
end
