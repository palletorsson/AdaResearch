extends Node

var content = """[font_size=28][b]Kusama's Polka Dots[/b][/font_size]
[i]Self-Obliteration[/i]

[i][color=gray]Summary: Inspired by Yayoi Kusama, this scene explores the aesthetic of accumulation and obsession. Mathematically, it is a study in high-frequency sine waves and thresholds. Philosophically, it is about the dissolution of the ego into the infinite field.[/color][/i]

[hr]

[b]1. The Infinite Field[/b]

Kusama's art uses repetition to overwhelm the senses. In code, we achieve this by modulating scale with a high-frequency grid function.

[color=green][b]Code[/b][/color]
[color=green][code]
# Inside a shader or loop
var grid_density = 20.0
var dot = sin(uv.x * grid_density) * sin(uv.y * grid_density)
[/code][/color]

By multiplying sine waves on different axes, we create a grid of peaks (dots) and troughs (voids).

[hr]

[b]2. The Threshold (Step)[/b]

To get hard-edged polka dots instead of soft gradients, we use a step function.

[color=green][b]Code[/b][/color]
[color=green][code]
# If dot > 0.5, return 1 (color), else 0 (void)
var is_dot = step(0.5, dot)
ALBEDO = mix(base_color, dot_color, is_dot)
[/code][/color]

[hr]

[b]3. Hallucination via Scroll[/b]

Kusama speaks of hallucinations where the pattern moves from the canvas to the wall, to the body, to the universe. We simulate this via UV scrolling.

[color=green][b]Code[/b][/color]
[color=green][code]
var scroll = TIME * 0.2
var uv_distorted = uv + vec2(sin(uv.y + scroll), cos(uv.x + scroll))
[/code][/color]

[hr]

[b]4. Obliteration[/b]

"Our earth is only one polka dot among a million stars in the cosmos." — Kusama

In this algorithm, the "individual" object loses its contour. It is camouflaged by the pattern of the world.

[color=orange][b]Critical Note:[/b][/color] Is this madness or liberation? To be lost in the pattern is to lose the burden of uniqueness. The algorithm treats every pixel the same; the pattern cares for none, yet encompasses all.

[hr]

[color=cyan][b]→ Next: Cables (Simulation)[/b][/color]
From abstract patterns to physical constraints.
"""

