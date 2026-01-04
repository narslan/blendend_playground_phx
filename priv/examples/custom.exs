width = 420
height = 420

draw width, height do
  clear(fill: rgb(242, 230, 216))
  rect(40, 40, 160, 80, fill: rgb(58, 102, 152))
  font = font("AlegreyaSans", 18)
  text(font, 40, 160, "Hello Blendend")
end
