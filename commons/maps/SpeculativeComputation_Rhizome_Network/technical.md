# Four interconnected chambers with no center — the rhizome as procedurally generated cave system

The bias map exposed classification as a structure that produces the categories it claims to discover. The wall divided the room. The embedding space divided the data. Every tree-structured system — every hierarchy, every taxonomy, every decision tree — operates through division: root to branch to leaf, each split an exclusion, each category a boundary.

The rhizome is the alternative. Deleuze and Guattari proposed a structure with no root, no trunk, no privileged path. Any point connects to any other. The cave system in this map generates such a structure: four chambers in the corners of a 10x10 grid, linked by narrow passages through height-5 walls. No chamber is the center. No path is canonical. The topology is rhizomatic.

## The Four-Chamber Layout

The structure layer encodes a complex topology through height values:

```
Height 0: voids — the central cross and corner gaps (impassable, no floor)
Height 1: passable floor — chambers and corridors
Height 5: walls — the barriers that define chamber boundaries
```

The four chambers occupy the grid's corners:
- **Northwest chamber**: rows 0-2, columns 0-2 (height 1)
- **Northeast chamber**: rows 0-2, columns 7-9 (height 1)
- **Southwest chamber**: rows 7-9, columns 0-2 (height 1)
- **Southeast chamber**: rows 7-9, columns 7-9 (height 1)

Between the chambers: height-5 walls and height-0 voids. The central positions (rows 4-5, columns 4-5) are void — no floor, no passage. The center of the map is empty. This is the anti-tree: in a tree, the root occupies the center and all paths radiate outward. Here, the center is void and all paths route around it.

The passages connecting chambers run along rows 2 and 7 (east-west corridors at height 1) and columns 2 and 7 (north-south corridors at height 1). Each corridor is one tile wide — narrow, requiring single-file passage. The narrowness is deliberate: passages in a rhizomatic network are not highways. They are mycorrhizal connections — thin threads linking nutrient-rich nodes.

```
Schematic (1=floor, 5=wall, 0=void):

NW-chamber  5  5  0  0  5  5  NE-chamber
     1      1  5  5  5  5  1       1
     5      1  1  1  1  1  1       5
     5      5  1  1  5  5  5       5
     0      5  1  5  0  0  5       0
     0      5  1  5  0  0  5       0
     5      5  1  1  5  5  5       5
     1      1  1  1  1  1  1       1
     1      0  1  5  5  5  5  1    1
     1      1  1  5  0  0  5  5    1
```

Multiple paths connect any two chambers. From NW to SE, the learner can traverse: NW east through row-2 corridor to NE, then south through column-7 corridor to SE. Or: NW south through column-2 corridor to SW, then east through row-7 corridor to SE. Or diagonal routes through intermediate passages. The path count is the topological argument: in a tree, one path connects any two nodes. In a rhizome, many paths connect, and no path is privileged.

## The Rhizome Cave Demo

The `rhizome_cave_demo` artifact sits at grid position (2,5) — in the western corridor, accessible from both NW and SW chambers:

```gdscript
# rhizome_cave_demo — procedural cave generation via density field + marching cubes
@export var grid_resolution: int = 32
@export var density_threshold: float = 0.5
@export var growth_iterations: int = 8
@export var branch_probability: float = 0.4
@export var merge_radius: float = 3.0
```

The artifact generates a miniature rhizome as a demonstration of the map's spatial principle. The process has three stages:

### Stage 1: Growth Nodes

```gdscript
func _generate_growth_nodes() -> Array[Dictionary]:
    var nodes := []
    var seed_count := 4  # One per chamber
    for i in range(seed_count):
        var seed_pos := _chamber_positions[i]
        nodes.append({"position": seed_pos, "radius": 1.5, "children": []})

    for _iteration in range(growth_iterations):
        var new_nodes := []
        for node in nodes:
            if randf() < branch_probability:
                var direction := Vector3(
                    randf_range(-1, 1),
                    randf_range(-0.3, 0.3),
                    randf_range(-1, 1)
                ).normalized()
                var child_pos := node["position"] + direction * step_size
                var child := {"position": child_pos, "radius": node["radius"] * 0.8}
                new_nodes.append(child)
                node["children"].append(child)
        nodes.append_array(new_nodes)
    return nodes
```

Four seeds — one per chamber. Each seed branches probabilistically (40% chance per iteration), producing child nodes at reduced radius. The growth is hierarchical at this stage: parent spawns children, children inherit reduced radius, the tree structure of biological branching.

### Stage 2: Density Field

```gdscript
func _nodes_to_density_field(nodes: Array) -> Array[float]:
    var field := []
    field.resize(grid_resolution ** 3)
    for voxel_index in range(field.size()):
        var voxel_pos := _index_to_position(voxel_index)
        var density := 0.0
        for node in nodes:
            var dist := voxel_pos.distance_to(node["position"])
            if dist < node["radius"] * 3.0:
                density += _falloff(dist, node["radius"])
        # Merge: nearby nodes blend their density contributions
        field[voxel_index] = density
    return field
```

Every node contributes a density falloff centered at its position. Where nodes are close — within `merge_radius` — their contributions overlap, producing a continuous density field that connects them. The density threshold determines where solid matter exists: above threshold = solid, below = void.

The key operation is the merge. When two branches from different seeds grow close enough, their density fields overlap. The marching cubes algorithm, extracting the isosurface at the threshold, produces a continuous tunnel connecting the branches. The connection is not prescribed — no edge was added to a graph. The connection emerged from spatial proximity in the density field. This is the rhizomatic principle: connection through adjacency, not through hierarchy.

### Stage 3: Marching Cubes

```gdscript
func _extract_surface(field: Array[float]) -> Mesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)

    for x in range(grid_resolution - 1):
        for y in range(grid_resolution - 1):
            for z in range(grid_resolution - 1):
                var cube_densities := _get_cube_corners(field, x, y, z)
                var config := _classify_cube(cube_densities, density_threshold)
                var triangles := MARCHING_CUBES_TABLE[config]
                for tri in triangles:
                    var vertex := _interpolate_edge(cube_densities, tri, density_threshold)
                    st.add_vertex(vertex)

    st.generate_normals()
    return st.commit()
```

The marching cubes algorithm walks through the density field one voxel cube at a time. Each cube has eight corners. Each corner is either above or below the density threshold, producing 2^8 = 256 possible configurations. A lookup table maps each configuration to a set of triangles that approximate the isosurface within that cube. The triangles, stitched together across the grid, form a continuous surface.

The surface does not know which growth node spawned which branch. The topology is discovered from the density field, not prescribed by the growth network. While the generation was hierarchical (nodes spawning children), the result is topologically continuous. The marching cubes algorithm treats the density field as a scalar field — no metadata about parentage, no record of which seed contributed. The surface is anonymous. Any point on it connects to any adjacent point through the mesh's face-edge topology.

This is the closest computation gets to rhizomatic structure: hierarchical generation producing non-hierarchical topology. The cave does not have a root. It has density concentrations. The tunnels do not have directions. They have curvature derived from the gradient of the density field.

## The Central Void

The map's center — rows 4-5, columns 4-5 — is void. Height 0. No floor. The learner cannot walk through the center. They must route around it, through the peripheral corridors.

In graph-theoretic terms, the map's navigability graph is a ring with cross-connections — high connectivity, no bottleneck. Removing the center removes the possibility of a hub-and-spoke topology. Every path is peripheral. Every route winds around the void.

The void is not absence. It is the map's structural assertion that the center need not be occupied. Traditional spatial design places the most important element at the center — the fountain in the piazza, the altar in the church, the root of the tree. The rhizome has no center because it has no root. The void at the map's center is the negative space that enables rhizomatic routing: because there is no hub, every path is equally valid. Because there is no center, every chamber is equally peripheral — which is to say, equally central.

## Deleuze and Guattari's Six Principles

The six principles of the rhizome, articulated in A Thousand Plateaus, map onto the cave system:

1. **Connection**: Any chamber connects to any other through multiple paths.
2. **Heterogeneity**: The corridors pass through different structural conditions — height-5 walls, height-0 voids, height-1 floors — encountering diverse terrain.
3. **Multiplicity**: The network cannot be reduced to a single description. Four chambers, multiple corridors, varying passage widths — no summary captures the topology without loss.
4. **Asignifying rupture**: Break a corridor and the network reroutes. The redundant connectivity means no single passage is critical.
5. **Cartography**: The map is always being made. The density field produces the surface; the surface produces the walkable space; the learner produces the path through walking.
6. **Decalcomania**: The rhizome is not a tracing of a pre-existing structure. It is a production — the density field generates the cave, the cave generates the connections, the connections generate the navigation.

The rhizome_cave_demo makes these principles procedural. The growth algorithm produces a density field. The density field produces a surface. The surface produces a topology. The topology is rhizomatic not because it was programmed to be but because the generation process — independent seeds growing toward each other, merging through density overlap — naturally produces multiply-connected structures.

## From Bias to Rhizome

The transition from the bias map to the rhizome map is the sequence's constructive turn. The bias map showed how tree-structured classification creates inequality: root to branch to leaf, each split producing a majority side and a minority side, the wall as hyperplane. The rhizome offers an alternative topology: no root, no split, no inside and outside. Connection without hierarchy. Navigation without permission.

The teleporter at (1,8) leads to the next map with the label "Next." The rhizome is not the solution to algorithmic bias — it is an alternative spatial logic, a demonstration that structures need not be arboreal, that knowledge need not be hierarchical, that connection can occur without classification. Whether this alternative scales from a 10x10 grid to an institutional architecture is the question the sequence leaves open.
