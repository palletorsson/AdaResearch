extends Node

var text = '''
[center][b]Neural Networks[/b][/center]
[center][i]Inside Neural Networks[/i][/center]

This tutorial card summarizes how `res://algorithms/machinelearning/neural_networks/NeuralNetworks.gd` orchestrates the scene so you can teach the concept without leaving VR.

[hr]
[b]Interactive Controls[/b]
- Inspector properties let you steer the demo without editing code.
[hr]
[b]Loop Highlights[/b]
- `[code]_ready()[/code]` handles a key part of the simulation loop.
- `[code]create_network()[/code]` handles a key part of the simulation loop.
- `[code]setup_materials()[/code]` handles a key part of the simulation loop.
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
