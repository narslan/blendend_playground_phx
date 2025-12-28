# Text.Multiline Example on https://fiddle.blend2d.com/.
# Shapes and centers multiple lines manually using Font metrics and GlyphRun.fill!/5.

alias Blendend.Text.{Face, Font, GlyphBuffer, GlyphRun}
width = 1800
height = 1800
draw width, height do
    
  font = load_font "priv/fonts/Alegreya-Regular.otf", 62.0
  fm = Font.metrics!(font)
  canvas = Blendend.Draw.get_canvas()   
    text = """
    Hello from blendend!
    This is a simple multiline text example
    that uses BLGlyphBuffer and Fill.glyph_run!   
    """

    lines = String.split(text, "\n", trim: true)
    num_lines = length(lines)
    {w, h} = {width * 0.7, height * 0.2}

    start_y = (h - num_lines * fm["size"] + fm["ascent"]) / 2.0
  
    line_height = fm["ascent"] + fm["descent"] + fm["line_gap"]

    fill_style = Blendend.Style.Color.rgb!(140, 25, 25)
     
    Enum.reduce(lines, start_y, fn line, y ->

      gb = GlyphBuffer.new!() 
        |> GlyphBuffer.set_utf8_text!(line)
        |> Font.shape!(font)
      
      gr =  Blendend.Text.GlyphRun.new!(gb)
      
      tm = Font.get_text_metrics!(font, gb)

      x = (w - (tm["bbox_x1"] - tm["bbox_x0"])) / 2.0

      GlyphRun.fill!(canvas, font, x, y, gr, fill: fill_style)

      y + line_height
    end)
end
