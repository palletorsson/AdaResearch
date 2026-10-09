# PG Percolation Network — Technical

Percolation stages the phase transition at which a random grid suddenly becomes connected. Each cell is occupied with probability p, and the algorithm finds the largest connected cluster.

```gdscript
class_name PercolationGrid extends Node3D

@export var grid_size: Vector2i = Vector2i(64, 64)
@export var probability: float = 0.5

var cells: Array = []  # 2D array of bool
var cluster_ids: Array = []  # 2D array of int

func _ready() -> void:
    regenerate()

func regenerate() -> void:
    cells.clear()
    for y in range(grid_size.y):
        var row: Array = []
        for x in range(grid_size.x):
            row.append(randf() < probability)
        cells.append(row)
    find_clusters()

func find_clusters() -> void:
    cluster_ids = []
    for y in range(grid_size.y):
        cluster_ids.append([])
        for x in range(grid_size.x):
            cluster_ids[y].append(-1)
    var next_id := 0
    for y in range(grid_size.y):
        for x in range(grid_size.x):
            if cells[y][x] and cluster_ids[y][x] == -1:
                flood_fill(x, y, next_id)
                next_id += 1
```

## Flood Fill

The cluster-finding routine uses iterative flood fill with a queue. Each cell is visited at most once; the total cost is O(W·H) per regeneration.

```gdscript
func flood_fill(x0: int, y0: int, id: int) -> void:
    var queue: Array = [Vector2i(x0, y0)]
    while not queue.is_empty():
        var p = queue.pop_back()
        if p.x < 0 or p.x >= grid_size.x or p.y < 0 or p.y >= grid_size.y:
            continue
        if not cells[p.y][p.x] or cluster_ids[p.y][p.x] != -1:
            continue
        cluster_ids[p.y][p.x] = id
        queue.append(p + Vector2i(1, 0))
        queue.append(p + Vector2i(-1, 0))
        queue.append(p + Vector2i(0, 1))
        queue.append(p + Vector2i(0, -1))
```

## The Critical Threshold

For site percolation on a 2D square lattice, the critical probability p_c is approximately 0.5927. Below this value, only small clusters form. Above, a spanning cluster almost surely exists. The transition is sharp: at p = p_c − 0.05, clusters are all small; at p = p_c + 0.05, one cluster spans the grid.

The scaling laws near p_c are universal: the largest cluster's mass scales as a power law in (p − p_c) with a critical exponent that depends only on the lattice dimension, not on the specific lattice. This is the source of percolation theory's broad applicability — the same universal exponents appear in fluid flow through porous media, epidemic spread, and network reliability.

## Bond vs Site

The map uses site percolation. Bond percolation occupies edges rather than vertices, producing a slightly different critical threshold (0.5 on 2D square lattices) and the same universal scaling exponents. The choice depends on the phenomenon being modelled — rock porosity is a site problem; electrical network reliability is a bond problem.

Within the sequence, Percolation is the connectivity chapter. PG_Branching_Growth will next compare rule-based and noise-driven growth as alternative generative strategies.

## Universality

The critical exponents of percolation are universal: they depend only on the lattice dimension, not on the specific lattice geometry. This is a surprising and powerful result that connects percolation to critical phenomena in physics more broadly. The same universal exponents describe phase transitions in ferromagnets, the liquid-gas transition in fluids, and the connectivity of large networks.

## Fractal Dimension of the Incipient Cluster

At exactly the critical threshold, the largest cluster is a fractal. Its mass M scales with the linear size L as M ~ L^(df), where df is the fractal dimension of the incipient cluster. For 2D site percolation, df = 91/48 ≈ 1.896. For 3D, df ≈ 2.52. These values are computed from the lattice's critical exponents.

```gdscript
func estimate_fractal_dimension(cluster: Array, sample_radii: Array) -> float:
    var points: Array = []
    for r in sample_radii:
        var count := 0
        for cell in cluster:
            if cell.distance_to(Vector2.ZERO) < r:
                count += 1
        points.append([log(r), log(count)])
    return linear_fit_slope(points)
```

The map's analysis panel estimates the fractal dimension at the current probability; near p_c the estimate converges to the theoretical value.

## Applications

Percolation theory underlies several practical problems. Fluid flow through porous rock is modeled as bond percolation where bonds are pore-connecting throats. Epidemic spread in a population is site percolation where sites are susceptible individuals. Electrical conductivity through a random mixture of conducting and insulating grains follows bond percolation with a conductivity-weighted critical exponent.

## Algorithm Variants

Invasion percolation grows a connected cluster by always adding the cell with the smallest random value. It produces self-organised critical clusters without tuning p. Explosive percolation uses an Achlioptas process to delay percolation by preferring to add bonds that keep clusters small, producing a sharper transition.
