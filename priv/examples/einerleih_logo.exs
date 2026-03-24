width = 550
height = 250

draw width, height do
  clear(fill: rgb(0, 0, 0, 0))
  font = font("Arvo", 48, "Regular")
  font2 = font("AlegreyaSans", 34, "Regular")
  font3 = font("MapleMono", 18, "Regular")
  text(font, 100, 60, "E I N E R L E I H", fill: rgb(255, 255, 255))
  text(font2, 160, 120, "LEIHPLATTFORM", fill: rgb(140, 174, 158))
  text(font3, 210, 180, "Aller 2026", fill: rgb(255, 255, 255))
end
