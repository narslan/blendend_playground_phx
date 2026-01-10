width = 150
height = 150

draw width, height do
  src = rgb(104, 199, 232)
  dest = rgb(255, 229, 0)
  rect(0, 0, 100, 100, fill: dest)
  rect(50, 50, 100, 100, fill: src, comp_op: :src_copy)
end
