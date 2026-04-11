extends Node

var text = '''
[center][b]K-Means Clustering[/b][/center]
[center][i]Inside K-Means Clustering[/i][/center]

This tutorial card summarizes how `res://algorithms/machinelearning/kmeansclustering/enhanced_kmeans.gd` orchestrates the scene so you can teach the concept without leaving VR.

[hr]
[b]Interactive Controls[/b]
- `[code]data_point_count[/code]` tweaks data point count in real time.
- `[code]cluster_count[/code]` tweaks cluster count in real time.
- `[code]iteration_speed[/code]` tweaks iteration speed in real time.
- `[code]convergence_threshold[/code]` tweaks convergence threshold in real time.
[hr]
[b]Loop Highlights[/b]
- `[code]_init()[/code]` handles a key part of the simulation loop.
- `[code]_ready()[/code]` handles a key part of the simulation loop.
- `[code]_process()[/code]` handles a key part of the simulation loop.
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
