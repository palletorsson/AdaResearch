extends Node

var content = """[font_size=28][b]Fourier Transform Shape[/b][/font_size]
[i]Drawing with Circles[/i]

[i][color=gray]Summary: Any 2D drawing (a closed loop) can be recreated by a series of rotating circles (epicycles). This is the visual application of the Fourier Transform. One circle sets the position, the next adds detail, the next adds texture.[/color][/i]

[hr]

[b]1. Epicycles[/b]

Imagine a clock hand rotating. Now, put another smaller clock hand at the tip of the first one, rotating faster. Now another.

The tip of the final hand traces a complex curve.

[color=green][b]Code[/b][/color]
[color=green][code]
var pos = Vector2.ZERO
for i in range(harmonics.size()):
    var radius = harmonics[i].amp
    var freq = harmonics[i].freq
    var phase = harmonics[i].phase
    
    var angle = time * freq + phase
    pos += Vector2(cos(angle), sin(angle)) * radius
[/code][/color]

[hr]

[b]2. Encoding a Shape[/b]

How do we find the right circles to draw a specific shape (like a cat, or the letter 'A')?
We take the coordinate list of the shape outline and run a Discrete Fourier Transform (DFT) on it. This gives us the list of radiuses and frequencies.

[hr]

[b]3. Compression[/b]

• The first few circles give the general blob shape.
• The next few define the corners and limbs.
• The hundreds of tiny circles define the jagged roughness.

If we throw away the small circles (low-pass filter), we "smooth" the shape.

[hr]

[b]4. The Universal Scribble[/b]

This proves that any line, no matter how complex or intentional, can be reduced to a sum of perfect, mindless rotations.

[color=orange][b]Critical Note:[/b][/color] Is handwriting personal? Or is it just a specific frequency spectrum? The machine does not see the meaning of your signature; it sees a list of phasors. It proves that complexity does not require complex parts—just the accumulation of simple cycles.

[hr]

[color=cyan][b]→ Next: Cables[/b][/color]
"""
