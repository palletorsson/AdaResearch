extends Node

var text = '''
[center][b]Neural Network Visualization[/b][/center]
[center][i]Inside Neural Network Visualization[/i][/center]

This tutorial card summarizes how `res://algorithms/machinelearning/neuralnetworkvisualization/neural_network_visualization.gd` orchestrates the scene so you can teach the concept without leaving VR.

[hr]
[b]Interactive Controls[/b]
- `[code]input_layer_size[/code]` tweaks input layer size in real time.
- `[code]hidden_layer_sizes[/code]` tweaks hidden layer sizes in real time.
- `[code]output_layer_size[/code]` tweaks output layer size in real time.
- `[code]learning_rate[/code]` tweaks learning rate in real time.
[hr]
[b]Loop Highlights[/b]
- `[code]_ready()[/code]` handles a key part of the simulation loop.
- `[code]_input()[/code]` handles a key part of the simulation loop.
- `[code]build_network()[/code]` handles a key part of the simulation loop.
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
