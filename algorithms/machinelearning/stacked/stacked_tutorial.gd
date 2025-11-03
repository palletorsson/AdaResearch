extends Node

var text = '''
[center][b]BuildEnv - Grammar Discovery RL Environment[/b][/center]
[center][i]Inside BuildEnv - Grammar Discovery RL Environment[/i][/center]

This tutorial card summarizes how `res://algorithms/machinelearning/stacked/LearnWorldStacked.gd` orchestrates the scene so you can teach the concept without leaving VR.

[hr]
[b]Interactive Controls[/b]
- `[code]arena_size_x[/code]` tweaks arena size x in real time.
- `[code]arena_size_z[/code]` tweaks arena size z in real time.
- `[code]grid_res[/code]` tweaks grid res in real time.
- `[code]settle_time[/code]` tweaks settle time in real time.
[hr]
[b]Loop Highlights[/b]
- `[code]_ready()[/code]` handles a key part of the simulation loop.
- `[code]_setup_environment()[/code]` handles a key part of the simulation loop.
- `[code]_create_material()[/code]` handles a key part of the simulation loop.
[color=yellow]Code[/color]
[code]
func _ready():
    # Core behaviour described in the tutorial
    pass
[/code]
[hr]
[b]Tips[/b]
- Toggle parameters, watch the metrics respond, and reset the scene to compare runs.
- Pair this with the README walkthrough for step-by-step experiments.
'''
