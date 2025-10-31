# Clustering Algorithms Sandbox

An interactive Godot scene that seeds a synthetic 2D dataset, clusters it with three lightweight heuristics, and visualises the results with colour-coded points and centroid markers. Switch between algorithms to see how cluster assignments and quality scores change in real time.

## Scene Assets
- `clustering_algorithms.tscn` — root scene with camera, ground plane, data/centroid containers, translucent radius disc, and HUD labels.
- `ClusteringAlgorithms.gd` — controller script that generates samples, runs K-Means / Agglomerative / DBSCAN, and updates the visual state.
- `code_prompt.txt` — prompt for regenerating the script with an AI assistant.
- `clustering_algorithms_tutorial.gd` — in-world BBCode tutorial card.
- `meta.json` — metadata for VR menus, search, and scene catalogues.

## How It Works
1. `_generate_dataset()` samples `sample_count` points around randomly spaced centres (plus optional uniform noise) using a deterministic `dataset_seed`.
2. `_build_point_meshes()` creates a `MeshInstance3D` for each datapoint, storing references to its mesh/material so later updates are cheap.
3. `run_clustering()` dispatches to one of the three algorithms:
   - **K-Means**: k initial centroids, a handful of Lloyd iterations.
   - **Agglomerative**: naive single-link merges until `cluster_count` groups remain.
   - **DBSCAN**: region query + expansion with configurable `eps` and `min_points`.
4. `_apply_cluster_visuals()` recolours points, lifts anomalies, and `_update_centroid_visuals()` emits glowing centroid spheres.
5. `_update_labels()` reports the selected algorithm, effective cluster count, inertia (average squared distance to centroids), and an approximate silhouette score.

## Exported Controls (Inspector)
- `sample_count` (30–600) – total samples to generate.
- `cluster_count` (2–6) – requested clusters for K-Means/Agglomerative.
- `cluster_spread` – Gaussian noise around base centres.
- `noise_ratio` – fraction of uniform “noise” points.
- `dbscan_eps` / `dbscan_min_points` – density thresholds for DBSCAN.
- `kmeans_iterations` – Lloyd iterations to run when in K-Means mode.
- `algorithm_mode` – initial algorithm selection (K-Means, Agglomerative, DBSCAN).
- `animate_clusters` – toggle the gentle Y-axis lift on assigned points.

### Helper Methods
- `run_clustering()` – recompute assignments after tweaking exports.
- Use `cycle_algorithm_mode()` from a button or console to compare algorithms on the same dataset.
- `reset_dataset(new_seed)` – reseed RNG, rebuild samples, rerun clustering.

## Usage Notes
- Changing any export (e.g., `cluster_count`, `dbscan_eps`) then calling `run_clustering()` immediately updates the visualisation.
- Use `cycle_algorithm_mode()` from a button or console to compare algorithms on the same dataset.
- The translucent disc scales to roughly cover the current dataset extent.

## Extending
- Hook UI sliders to thresholds for live exploration sessions.
- Replace the synthetic generator with logged telemetry or embed dimensionality reduction for higher-D data.
- Add hull meshes or connection lines per cluster for deeper insight into algorithm behaviour.
