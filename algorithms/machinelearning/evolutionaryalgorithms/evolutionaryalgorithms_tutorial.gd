extends Node

var text = '''
[center][b]Evolving Creatures Simulation[/b][/center]
[center][i]Inside Evolving Creatures Simulation[/i][/center]

This tutorial card summarizes how `res://algorithms/machinelearning/evolutionaryalgorithms/evolving_creatures.gd` orchestrates the scene so you can teach the concept without leaving VR.

[hr]
[b]Interactive Controls[/b]
- `[code]limb_length[/code]` tweaks limb length in real time.
- `[code]limb_radius[/code]` tweaks limb radius in real time.
- `[code]torque_strength[/code]` tweaks torque strength in real time.
- `[code]creature_type[/code]` tweaks creature type in real time.
[hr]
[b]Loop Highlights[/b]
- `[code]_ready()[/code]` handles a key part of the simulation loop.
- `[code]_process()[/code]` handles a key part of the simulation loop.
- `[code]create_environment()[/code]` handles a key part of the simulation loop.
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
