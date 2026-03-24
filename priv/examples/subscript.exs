alias Blendend.Text.{Face, Font, GlyphBuffer, GlyphRun}
# A4 Size
width = 800
height = 800

draw width, height do
  face = Face.load!("priv/fonts/Alegreya-Regular.otf")
  font = Font.create!(face, 60)

  tokens = [
    {:normal, "C"},
    {:normal, "H"},
    {:cluster,
     [
       {:sup, "+"},
       {:sub, "3"}
     ]}
  ]

  c = Blendend.Draw.get_canvas()

  BlendendPlaygroundPhx.Text.InlineLayout.layout_inline(
    tokens,
    font,
    100,
    100,
    canvas: c,
    face: face
  )
end
