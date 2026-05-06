extends Node

var text = '''
[center][b]Gradient Descent Sandbox[/b][/center]
[center][i]Inside Gradient Descent Sandbox[/i][/center]

This tutorial card summarizes how `res://algorithms/machinelearning/gradientdescent/GradientDescentDemo.gd` orchestrates the scene so you can teach the concept without leaving VR.

[hr]
[b]Interactive Controls[/b]
- `[code]grid_size[/code]` tweaks grid size in real time.
- `[code]height_scale[/code]` tweaks height scale in real time.
- `[code]noise_frequency[/code]` tweaks noise frequency in real time.
- `[code]noise_lacunarity[/code]` tweaks noise lacunarity in real time.
[hr]
[b]Loop Highlights[/b]
- `[code]_ready()[/code]` handles a key part of the simulation loop.
- `[code]_init_noise()[/code]` handles a key part of the simulation loop.
- `[code]_generate_terrain()[/code]` handles a key part of the simulation loop.
[color=yellow]Code[/color]
[code]
func _ready() -> void:
    # Core behaviour described in the tutorial
    pass
[/code]
[hr]
[b]Tips[/b]
- Toggle parameters, watch the metrics respond, and reset the scene to compare runs.
- Pair this with the README walkthrough for step-by-step experiments.
'''
