# Decision Boundary Viewer

An interactive 2D classification visualizer that demonstrates how a linear classifier separates two clusters of data points, teaching the fundamentals of machine learning decision boundaries and classification accuracy.

## How It Works

Two Gaussian clusters (class A and class B) are generated on a 128x128 floor quad. A linear classifier defined by `w1*x + w2*y + bias = 0` divides the space into two colored regions (blue for class 0, red for class 1). The decision boundary is rendered as a yellow band where the activation is near zero. Data points are drawn as colored dots, with misclassified points marked by white corner pixels. Three VR sliders let the user adjust w1, w2, and bias in real time, and a live accuracy percentage updates as the boundary moves.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `plot_size` | float | `0.7` |
| `plot_resolution` | int | `128` |
| `num_points_per_class` | int | `30` |

## Features

- Procedurally generated 128x128 classification heatmap texture
- Two Gaussian data clusters with configurable point count
- VR sliders for w1, w2, and bias weights (range -3 to +3 and -2 to +2)
- Live accuracy counter and formula display
- Yellow decision boundary band visualization
- White markers highlighting misclassified points

## Files

- `decision_boundary_viewer.gd` — Main script
- `decision_boundary_viewer.tscn` — Scene file
