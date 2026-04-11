extends Node

var text = '''
[center][b]Support Vector Machine Visualization[/b][/center]
[center][i]Inside Support Vector Machine Visualization[/i][/center]

This tutorial card summarizes how `res://algorithms/machinelearning/supportvectormachine/svm_visualization.gd` orchestrates the scene so you can teach the concept without leaving VR.

[hr]
[b]Interactive Controls[/b]
- `[code]kernel_type[/code]` tweaks kernel type in real time.
- `[code]C_parameter[/code]` tweaks C parameter in real time.
- `[code]gamma[/code]` tweaks gamma in real time.
- `[code]degree[/code]` tweaks degree in real time.
[hr]
[b]Loop Highlights[/b]
- `[code]_init()[/code]` handles a key part of the simulation loop.
- `[code]_ready()[/code]` handles a key part of the simulation loop.
- `[code]setup_ui()[/code]` handles a key part of the simulation loop.
[color=yellow]Code[/color]
[code]
func _init() -> void:
    # Core behaviour described in the tutorial
    pass
[/code]
[hr]
[b]Tips[/b]
- Toggle parameters, watch the metrics respond, and reset the scene to compare runs.
- Pair this with the README walkthrough for step-by-step experiments.
'''
