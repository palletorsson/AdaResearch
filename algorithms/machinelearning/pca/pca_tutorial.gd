extends Node

var text = '''
[center][b]Principal Component Analysis (PCA) Visualization[/b][/center]
[center][i]Inside Principal Component Analysis (PCA) Visualization[/i][/center]

This tutorial card summarizes how `res://algorithms/machinelearning/pca/pca_visualization.gd` orchestrates the scene so you can teach the concept without leaving VR.

[hr]
[b]Interactive Controls[/b]
- `[code]num_dimensions[/code]` tweaks num dimensions in real time.
- `[code]target_dimensions[/code]` tweaks target dimensions in real time.
- `[code]show_all_components[/code]` tweaks show all components in real time.
- `[code]normalize_data[/code]` tweaks normalize data in real time.
[hr]
[b]Loop Highlights[/b]
- `[code]_init()[/code]` handles a key part of the simulation loop.
- `[code]_ready()[/code]` handles a key part of the simulation loop.
- `[code]setup_ui()[/code]` handles a key part of the simulation loop.
[color=yellow]Code[/color]
[code]
func _init():
    # Core behaviour described in the tutorial
    pass
[/code]
[hr]
[b]Tips[/b]
- Toggle parameters, watch the metrics respond, and reset the scene to compare runs.
- Pair this with the README walkthrough for step-by-step experiments.
'''
