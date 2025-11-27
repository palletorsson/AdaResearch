extends Node

var content = """[font_size=28][b]Beat Frequencies[/b][/font_size]
[i]The Interference of Closeness[/i]

[i][color=gray]Summary: When two waves of slightly different frequencies overlap, they create a new, pulsing wave called a "beat." The beat frequency is the difference between the two. This phenomenon reveals that dissonance is just proximity—a tension that resolves into a cycle.[/color][/i]

[hr]

[b]1. The Sum of Waves[/b]

Wave A has frequency 440 Hz. Wave B has frequency 442 Hz.
When summed:
[code]y = sin(440 * t) + sin(442 * t)[/code]

They start in phase (summing to 2x).
After a while, they drift out of phase (canceling to 0).
Then they return.

[hr]

[b]2. The Envelope[/b]

The result sounds like a single tone at 441 Hz (the average) that pulses in volume at 2 Hz (the difference). This pulse is the "beat."

[color=green][b]Code[/b][/color]
[color=green][code]
var freq1 = 10.0
var freq2 = 11.0
var beat_freq = abs(freq1 - freq2)

# The beat envelope
var envelope = cos(beat_freq * time * PI)
[/code][/color]

[hr]

[b]3. Binaural Beats[/b]

If you play 440 Hz in the left ear and 442 Hz in the right, the "beat" does not exist in the air. It is constructed entirely inside the brain stem (superior olivary complex). The brain manufactures the interference.

[color=orange][b]Critical Note:[/b][/color] Difference creates rhythm. In a system where everything is identical, there is only stasis. It is the slight deviation—the error, the drift, the detuning—that creates the pulse of life. Perfection is flatline.

[hr]

[color=cyan][b]→ Next: Harmonic Series[/b][/color]
Building complexity from simple integers.
"""
