extends Node

var text = '''
[center][b]Random Forest Visualization[/b][/center]
[center][i]Inside Random Forest Visualization[/i][/center]

This tutorial card summarizes how `res://algorithms/machinelearning/randomforest/random_forest_visualization.gd` orchestrates the scene so you can teach the concept without leaving VR.

[hr]
[b]Interactive Controls[/b]
- `[code]num_trees[/code]` tweaks num trees in real time.
- `[code]max_depth[/code]` tweaks max depth in real time.
- `[code]min_samples_split[/code]` tweaks min samples split in real time.
- `[code]max_features[/code]` tweaks max features in real time.
[hr]
[b]Loop Highlights[/b]
- `[code]_init()[/code]` handles a key part of the simulation loop.
- `[code]train()[/code]` handles a key part of the simulation loop.
- `[code]build_tree()[/code]` handles a key part of the simulation loop.
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
