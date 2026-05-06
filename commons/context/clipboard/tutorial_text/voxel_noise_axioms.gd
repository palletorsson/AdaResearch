extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Voxel Noise[/b][/font_size][/center]
[center][i]Discretizing the Continuum[/i][/center]

[b]From Field to Block[/b]

Noise is mathematically continuous—a smooth field of values.
But computers are discrete. To build a world, we must **sample** or **quantize** that field.

Here, we turn the smooth noise function into **Voxels** (Volumetric Pixels).

[hr]

[b]Thresholding[/b]

How do we decide where to place a block?
[code]
if noise(x, y, z) > threshold:
    place_block(x, y, z)
else:
    empty_space()
[/code]

This simple rule creates caves, islands, and Swiss-cheese structures.

[hr]

[b]The "Minecraft" Effect[/b]

This is the foundational algorithm of nearly all infinite voxel games.
1. Generate 3D noise field.
2. If value > 0, it's solid ground.
3. If value < 0, it's air (cave).

[color=pink]Critical Thought: We are imposing a grid on a fluid reality. The "blockiness" is not in the math (the noise is smooth); it is in our sampling method. We force the organic into the box.[/color]
'''
