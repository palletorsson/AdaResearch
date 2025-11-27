extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Noise Layers[/b][/font_size][/center]
[center][i]The Symphony of Frequencies[/i][/center]

[b]One Note vs. A Chord[/b]

A single layer of noise is like a sine wave—smooth, predictable, lacking texture.
To get the complexity of nature (mountains, bark, clouds), we need **Octaves**.

[hr]

[b]Fractal Summation[/b]

We add multiple layers of noise together, each with:
1. **Higher Frequency** (closer together)
2. **Lower Amplitude** (less influence)

[color=yellow][b]The Recipe:[/b][/color]
[code]
Total = Noise(x) * 1.0        # Octave 1: Mountains
      + Noise(x*2) * 0.5      # Octave 2: Boulders
      + Noise(x*4) * 0.25     # Octave 3: Rocks
      + Noise(x*8) * 0.125    # Octave 4: Pebbles
[/code]

[hr]

[b]Interactable: The Noise Torus[/b]

This torus is displaced by noise.
- **Use the sliders** to change:
  - [b]Frequency:[/b] How "zoomed in" the noise is.
  - [b]Octaves:[/b] How much detail is added.
  - [b]Persistence:[/b] How "rough" the fine details are.

[color=pink]Queer Theory Note: Identity is not a single variable. It is an intersection of multiple frequencies—layers of context, history, and expression summing up to a complex surface.[/color]
'''

