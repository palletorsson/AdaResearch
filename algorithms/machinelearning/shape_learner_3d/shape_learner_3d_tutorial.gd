extends Node

var text = '''
[center][b]Shape Learner 3D[/b][/center]
[center][i]Inside Shape Learner 3D[/i][/center]

This tutorial card summarizes how `res://algorithms/machinelearning/shape_learner_3d/ShapeLearner3D.gd` orchestrates the scene so you can teach the concept without leaving VR.

[hr]
[b]Interactive Controls[/b]
- `[code]grid_size[/code]` tweaks grid size in real time.
- `[code]population_size[/code]` tweaks population size in real time.
- `[code]mutation_rate[/code]` tweaks mutation rate in real time.
- `[code]generations[/code]` tweaks generations in real time.
[hr]
[b]Loop Highlights[/b]
- `[code]_ready()[/code]` handles a key part of the simulation loop.
- `[code]_process()[/code]` handles a key part of the simulation loop.
- `[code]run_ga_generation()[/code]` handles a key part of the simulation loop.
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
