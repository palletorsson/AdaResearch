extends Node

var content = """[font_size=28][b]Wave Propagation[/b][/font_size]
[i]The Medium is the Message[/i]

[i][color=gray]Summary: A wave is not an object; it is a disturbance traveling through a medium. In 3D space, waves emanate from a source, diminishing in power as they spread (inverse square law). This tutorial explores how to simulate the ripple of influence across a grid.[/color][/i]

[hr]

[b]1. The Distance Field[/b]

To simulate a ripple, we calculate the distance from a source point to every other point.

[color=green][b]Code[/b][/color]
[color=green][code]
var source_pos = Vector3(0, 0, 0)
var my_pos = transform.origin
var dist = source_pos.distance_to(my_pos)
[/code][/color]

[hr]

[b]2. The Wave Function[/b]

We subtract the distance from time. This makes the phase of the sine wave depend on how far away we are.

[color=green][b]Code[/b][/color]
[color=green][code]
var speed = 5.0
var frequency = 2.0
var wave = sin(time * speed - dist * frequency)
[/code][/color]

If [code]dist[/code] increases, the term inside [code]sin()[/code] decreases, shifting the wave "outward" from the center.

[hr]

[b]3. Attenuation (Fading)[/b]

Real waves lose energy. A shout becomes a whisper. Light creates shadows.

[color=green][b]Code[/b][/color]
[color=green][code]
# Inverse square law approximation
var energy = 1.0 / (1.0 + dist * dist)
var final_height = wave * energy
[/code][/color]

[hr]

[b]4. Interference[/b]

When two waves meet, they sum. Two peaks make a mountain; a peak and a trough make silence (cancellation).

[color=orange][b]Critical Note:[/b][/color] Identity is permeable. In a wave system, no point is isolated. My movement is the sum of all waves passing through me. I am not a static entity, but a point of intersection for the world's noise. To exist in a medium is to be distorted by it.

[hr]

[color=cyan][b]→ Next: Kusama (Obsession)[/b][/color]
What happens when the wave becomes a pattern that consumes the self?
"""

