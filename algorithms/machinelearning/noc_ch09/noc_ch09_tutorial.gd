extends Node

var text = '''
[center][b]Nature of Code Chapter 09[/b][/center]
[center][i]Inside Nature of Code Chapter 09[/i][/center]

This tutorial card summarizes how `res://algorithms/machinelearning/noc_ch09/9_1_ga_shakespeare_vr.gd` orchestrates the scene so you can teach the concept without leaving VR.

[hr]
[b]Interactive Controls[/b]
- Inspector properties let you steer the demo without editing code.
[hr]
[b]Loop Highlights[/b]
- `[code]_ready()[/code]` handles a key part of the simulation loop.
- `[code]_setup_environment()[/code]` handles a key part of the simulation loop.
- `[code]_create_controller()[/code]` handles a key part of the simulation loop.
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
