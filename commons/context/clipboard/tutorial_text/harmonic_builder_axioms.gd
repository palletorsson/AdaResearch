extends Node

var content = """[font_size=28][b]Harmonic Synthesis[/b][/font_size]
[i]The Architecture of Timbre[/i]

[i][color=gray]Summary: Any complex repeating wave can be built by summing simple sine waves at integer multiples of a fundamental frequency. This is the Harmonic Series. It is how nature constructs the "color" of sound (timbre).[/color][/i]

[hr]

[b]1. The Fundamental[/b]

The first harmonic (f) is the root note. It defines the pitch.
[code]y = sin(f * t)[/code]

[hr]

[b]2. The Overtones[/b]

We add waves at 2f, 3f, 4f, etc.
Each harmonic has a smaller amplitude (usually 1/n).

[color=green][b]Code[/b][/color]
[color=green][code]
var wave = 0.0
for i in range(1, 10):
    var harmonic = i
    var amp = 1.0 / i  # Sawtooth wave formula
    wave += sin(time * freq * harmonic) * amp
[/code][/color]

[hr]

[b]3. Wave Shapes[/b]

• [b]Square Wave:[/b] Odd harmonics only (1, 3, 5...), amplitude 1/n.
• [b]Sawtooth Wave:[/b] All harmonics (1, 2, 3...), amplitude 1/n.
• [b]Triangle Wave:[/b] Odd harmonics, amplitude 1/n^2.

[hr]

[b]4. The Godot Approach[/b]

In this scene, you can manually adjust the amplitude of each harmonic. You are acting as a Fourier Synthesizer.

[color=orange][b]Critical Note:[/b][/color] Complexity is reducible. The most jagged, aggressive, or strange waveform is just a choir of simple sine waves singing in perfect integer ratios. Chaos is often just order that we haven't decomposed yet.

[hr]

[color=cyan][b]→ Next: Fourier Transform[/b][/color]
Reversing the process: extracting the choir from the song.
"""

