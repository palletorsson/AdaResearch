extends Node

var content = """[font_size=28][b]The Oscillating Wave[/b][/font_size]
[i]Energy in Motion[/i]

[i][color=gray]Summary: A wave is energy moving through a medium. In this visualization, we see the fundamental relationship between Amplitude (energy), Frequency (speed), and Phase (time).[/color][/i]

[hr]

[b]1. The Equation[/b]

[code]y = A * sin(B * (x - C)) + D[/code]

• [b]A (Amplitude):[/b] Height of the peak. How loud is the sound? How bright is the light?
• [b]B (Frequency):[/b] Cycles per unit. How high is the pitch?
• [b]C (Phase Shift):[/b] Horizontal offset. Movement in time.
• [b]D (Vertical Shift):[/b] Baseline offset.

[hr]

[b]2. Transverse vs. Longitudinal[/b]

• [b]Transverse:[/b] Particles move up/down (water, light).
• [b]Longitudinal:[/b] Particles move back/forth (sound).

In computer graphics, we almost always visualize waves as transverse because they read better on a 2D screen.

[hr]

[b]3. Damping[/b]

Real oscillation decays. Friction steals energy.
[code]y = exp(-k * t) * cos(w * t)[/code]

This exponential decay creates the "ringing" effect of a bell or a plucked string.

[color=orange][b]Critical Note:[/b][/color] Perpetual motion is a digital lie. In the physical world, silence is the inevitable destination of all vibration. We simulate damping to make the world feel "heavy" and real.

[hr]

[color=cyan][b]→ Next: Spherical Harmonics[/b][/color]
When the wave is wrapped around a sphere.
"""
