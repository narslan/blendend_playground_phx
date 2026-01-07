width = 820
height = 820

draw width, height do
  clear(fill: rgb(242, 230, 216))
  rect(40, 40, 160, 80, fill: rgb(58, 102, 152))
  font = font("AlegreyaSans", 48, "Bold")
  text(font, 200, 160, "Hello blendend!")
end
