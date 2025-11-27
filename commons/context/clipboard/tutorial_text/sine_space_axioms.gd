extends Node

var content = """[font_size=28][b]The Sine Wave[/b][/font_size]
[i]The Eternal Return[/i]

[i][color=gray]Summary: The sine wave is the fundamental atom of oscillation. It maps the rotation of a circle over time, creating a perfect, repeating cycle. In code, it breathes life into static coordinates, turning position into rhythm. But its perfection is also a trap—a closed loop that never evolves.[/color][/i]

[hr]

[b]1. The Mathematics of Breath[/b]

The sine function [code]sin(t)[/code] transforms a linear input (time) into a cyclical output (oscillation between -1 and 1). It is the heartbeat of procedural animation.

[color=green][b]Code[/b][/color]
[color=green][code]
var time = Time.get_ticks_msec() / 1000.0
var amplitude = 2.0  # How far it moves
var frequency = 1.0  # How fast it cycles

# The basic breath
var y = sin(time * frequency) * amplitude
position.y = y
[/code][/color]

Every periodic motion in nature—tides, heartbeats, pendulums—can be approximated by this function.

[hr]

[b]2. Spatializing Time[/b]

When we apply the sine wave across space, we create a wave. The position of each point (x) offsets its phase in time.

[color=green][b]Code[/b][/color]
[color=green][code]
# A wave moving through space
var phase_offset = x_coordinate * 0.5
var y = sin(time + phase_offset)
[/code][/color]

This simple offset creates the illusion of propagation. The points do not move sideways; they only move up and down. The "wave" is an emergent property of their collective timing.

[hr]

[b]3. The Trap of the Cycle[/b]

The sine wave is predictable. [code]sin(t)[/code] will always return to where it started. It is a closed system of history.

[color=orange][b]Critical Note:[/b][/color] In a world governed purely by sine waves, nothing new can ever happen. There is no trauma, no growth, no decay—only the eternal return of the same value.

To break the loop, we must introduce:
• [b]Noise[/b] (Chaos/texture)
• [b]Decay[/b] (Entropy/loss)
• [b]Interference[/b] (Relationship/collision)

[hr]

[color=cyan][b]→ Next: Audio Reactivity[/b][/color]
We will break the silence by injecting external signals.
"""

