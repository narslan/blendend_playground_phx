# Mask fill demo inspired by the Blend2D Tcl sample; 
# https://abu-irrational.github.io/tclBlend2d-Gallery/cards/sample157.html
# stamps a grayscale splash mask in layered colors.
alias Blendend.{Image}
alias Blendend.Canvas.Mask

canvas_w = 520
canvas_h = 520

draw canvas_w, canvas_h do
  clear(fill: rgb(255, 255, 255))

  canvas = Blendend.Draw.get_canvas()
  # Use red channel as coverage; 
  mask = Image.from_file_a8!("priv/images/splash.png", :red)


  Mask.blur_fill!(canvas, mask, 0, 0, 4.0, fill: rgb(0,0,0), alpha: 0.2)  
  Mask.fill!(canvas, mask, -5, -20,
    fill: rgb(0, 80, 210), # light blue
    alpha: 0.4
  )
  #Mask.blur_fill!(canvas, mask, -5, -20, 1.1)

  Mask.blur_fill!(canvas, mask, -155, 100, 4.0, fill: rgb(0,0,0), alpha: 0.3)  
  Mask.fill!(canvas, mask, -150.0, 105.0,
    fill: rgb(255, 255, 0), # yellow
    alpha: 0.5
  )

  Mask.blur_fill!(canvas, mask, 55, -50, 4.0, fill: rgb(0,0,0), alpha: 0.3)  
  Mask.fill!(canvas, mask, 50.0, -45.0,
    fill: rgb(255, 0, 0), # red
    alpha: 0.3
  )
end
