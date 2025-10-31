extends Node

# Tutorial card rendered in-world via BBCode
var text = '''
[center][b]Clustering Algorithms[/b][/center]
[center][i]K-Means, Agglomerative, DBSCAN in one sandbox[/i][/center]

[hr]
[b]What You See[/b]
- Teal/orange/purple points = cluster memberships.
- Grey points = DBSCAN noise or unassigned samples.
- Glowing spheres = centroid markers.
- Translucent disc ≈ dataset radius.

[hr]
[b]Controls[/b]
[color=yellow]Methods[/color]
[code]
run_clustering()
cycle_algorithm_mode()
reset_dataset(new_seed)
[/code]
[color=yellow]Exports[/color]
`sample_count`, `cluster_count`, `cluster_spread`, `noise_ratio`, `dbscan_eps`, `dbscan_min_points`, `kmeans_iterations`, `algorithm_mode`.

[hr]
[b]Algorithm Notes[/b]
- [b]K-Means[/b]: Lloyd steps with fixed k.
- [b]Agglomerative[/b]: Single-link merges until target clusters.
- [b]DBSCAN[/b]: Density filter; noise stays grey.

[hr]
[b]Try This[/b]
1. Increase `noise_ratio`, rerun DBSCAN, watch the grey halo.
2. Lower `kmeans_iterations` to show poor centroids.
3. `cycle_algorithm_mode()` to compare cluster boundaries.

[hr]
[i]Tip[/i]
Expose helper methods on UI buttons or VR dials for live workshops.
'''
