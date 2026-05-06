# Small World Network

An interactive Watts-Strogatz small-world network where 20 nodes form a ring lattice with nearest-neighbor connections, and a VR slider controls the rewiring probability p. Teaches how random shortcuts dramatically reduce average path length while preserving high clustering -- the "small world" phenomenon.

## How It Works

The network starts as a regular ring lattice: each node connects to its k nearest neighbors on each side. When the rewiring probability p is increased via the VR slider, each edge is randomly reassigned to a different target node with probability p, creating long-range shortcuts. After each rewire, BFS computes the average shortest path length L across all node pairs, and the clustering coefficient C is calculated by counting triangles around each node. The display shows how even a small p (a few shortcuts) collapses L while C stays high -- the signature of small-world topology.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `node_count` | int | 20 |
| `k_neighbors` | int | 4 |
| `graph_radius` | float | 0.30 |
| `node_radius` | float | 0.015 |
| `edge_width` | float | 0.003 |

## Features

- Watts-Strogatz rewiring with configurable probability p
- Live computation of average path length (BFS) and clustering coefficient
- Nodes colored by degree: blue (low) to red (high)
- Edges colored to distinguish original (gray) from rewired shortcuts (yellow)
- VR slider for rewiring probability and push button to trigger rewire
- Stats display showing p, L, and C values

## Files

- `small_world_network.gd` -- Main script
- `small_world_network.tscn` -- Scene file
