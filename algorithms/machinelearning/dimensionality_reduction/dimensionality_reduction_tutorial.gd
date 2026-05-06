extends Node

var text = '''
[center][b]Dimensionality Reduction[/b][/center]
[center][i]Inside Dimensionality Reduction[/i][/center]

This tutorial card summarizes how `res://algorithms/machinelearning/dimensionality_reduction/DimensionalityReduction.gd` orchestrates the scene so you can teach the concept without leaving VR.

[hr]
[b]Interactive Controls[/b]
- Inspector properties let you steer the demo without editing code.
[hr]
[b]Loop Highlights[/b]
- `[code]_ready()[/code]` handles a key part of the simulation loop.
- `[code]_process()[/code]` handles a key part of the simulation loop.
- `[code]create_high_dimensional_particles()[/code]` handles a key part of the simulation loop.
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
