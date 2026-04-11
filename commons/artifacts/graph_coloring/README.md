# Graph Coloring

Demonstrates the greedy graph coloring algorithm on the Petersen graph, a classic 3-regular graph with 10 nodes and 15 edges, revealing how the chromatic number emerges from step-by-step color assignment.

## How It Works

The Petersen graph is constructed with 5 outer pentagon nodes and 5 inner pentagram nodes connected by 15 edges. The greedy coloring algorithm processes nodes one at a time: for each node, it assigns the lowest color index not already used by any adjacent neighbor. Nodes begin uncolored (grey) and are assigned from a 4-color palette (red, blue, green, yellow) with a brief scale-pulse animation on each step. After all nodes are colored, the chromatic number (minimum colors used) is displayed. Edge lines brighten when both endpoints are colored.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `node_radius` | float | `0.018` |
| `edge_width` | float | `0.003` |
| `graph_radius_outer` | float | `0.28` |
| `graph_radius_inner` | float | `0.12` |
| `color_step_delay` | float | `0.35` |

## Features

- Step-by-step animated greedy coloring with tween-based node pulse
- Petersen graph topology (pentagon + pentagram + spokes)
- Chromatic number display upon completion
- Edges brighten as their endpoints get colored
- Configurable animation speed via color_step_delay

## Files

- `graph_coloring.gd` -- Main script
- `graph_coloring.tscn` -- Scene file
