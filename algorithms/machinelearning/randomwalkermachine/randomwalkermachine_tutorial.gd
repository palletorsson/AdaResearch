extends Node

var text = '''
[center][b]Random Walker Machine[/b][/center]
[center][i]Inside Random Walker Machine[/i][/center]

This tutorial card summarizes how `res://algorithms/machinelearning/randomwalkermachine/randomwalkermachine.gd` orchestrates the scene so you can teach the concept without leaving VR.

[hr]
[b]Interactive Controls[/b]
- Inspector properties let you steer the demo without editing code.
[hr]
[b]Loop Highlights[/b]
- `[code]_init()[/code]` handles a key part of the simulation loop.
- `[code]update_position()[/code]` handles a key part of the simulation loop.
- `[code]_ready()[/code]` handles a key part of the simulation loop.
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
