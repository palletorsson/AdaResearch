extends Node

# Tutorial card rendered in-world via BBCode
var text = '''
[center][b]Anomaly Detection Sandbox[/b][/center]
[center][i]Three scoring heuristics on a synthetic dataset[/i][/center]

[hr]
[b]Scene Layout[/b]
- Teal points = normal samples clustered near the origin.
- Red points = scored above the active threshold.
- Translucent disc = visual hint of the decision boundary.
- Billboard labels report the current mode and summary stats.

[hr]
[b]Controls[/b]
[color=yellow]Methods[/color]
[code]
cycle_detection_mode()
reset_dataset(new_seed)
run_detection()
[/code]
- Exported thresholds (z-score / radius / error) adjust sensitivity.
- nomaly_scale_multiplier exaggerates flagged points.

[hr]
[b]Heuristics[/b]
- Z-Score: |zₓ| + |zᵧ| vs. threshold.
- Isolation Radius: distance from the cluster centre.
- Autoencoder Error: distance to sin-wave manifold + radial penalty.

[hr]
[b]Experiments[/b]
1. Lower each threshold to see how false positives emerge.
2. Call eset_dataset() with a new seed for fresh samples.
3. Toggle through modes to compare which points flip classification.

[hr]
[i]Tip[/i]
Expose the helper methods on a UI button or VR dial to make the demo interactive.
'''
