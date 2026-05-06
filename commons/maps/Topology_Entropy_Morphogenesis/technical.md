# Entropy becoming form — gyroid surfaces, marching cubes, and the morphogenesis of topology

The sequence's final map bridges soft body dynamics to mathematical abstraction. A gyroid — a triply-periodic minimal surface — is generated through marching cubes, with a single entropy parameter S controlling the transition from smooth periodic order to noisy fragmented chaos. Maximum matching on general graphs completes the theoretical arc: structure emerges not from design but from constraint satisfaction in a field of possibilities.

## The Gyroid: Triply-Periodic Minimal Surface

A gyroid is a minimal surface — a surface with zero mean curvature at every point, meaning it locally minimizes area. The gyroid is also triply-periodic: it repeats in all three spatial directions, tiling space with two interlocking labyrinthine channels separated by the surface. The implicit equation:

```
sin(x) * cos(y) + sin(y) * cos(z) + sin(z) * cos(x) = 0
```

This equation defines a scalar field in 3D space. The surface is the zero-level set — all points where the field equals zero. Points where the field is positive are on one side of the surface; negative points are on the other. The two sides form the two channel systems.

```gdscript
# From entropy_morphogenesis @identity:
# frequency = lerp(0.9, 1.6, S)
# noise_amp = lerp(0.05, 0.20, S)
# threshold = center + wobble * (S - 0.5) * 2

@export var S: float = 0.3  # entropy parameter

func _compute_gyroid_field(x: float, y: float, z: float) -> float:
    var freq := lerpf(0.9, 1.6, S)
    var noise := _noise_3d(x, y, z) * lerpf(0.05, 0.20, S)
    var field := sin(x * freq) * cos(y * freq) + \
                 sin(y * freq) * cos(z * freq) + \
                 sin(z * freq) * cos(x * freq)
    return field + noise
```

The entropy parameter S modulates three quantities simultaneously:

**Frequency** (0.9 to 1.6): Higher frequency means more repetitions per unit volume. At low S, the gyroid has broad, smooth passages. At high S, the passages multiply and narrow, creating denser lattice structure.

**Noise amplitude** (0.05 to 0.20): Noise perturbs the scalar field, disrupting the mathematical perfection of the gyroid equation. At low S, perturbation is barely visible — the surface is nearly ideal. At high S, noise fragments the surface, breaking passages, creating isolated chambers, disrupting periodicity.

**Threshold**: The isosurface level shifts with S, opening or closing passages. At S = 0.5, the threshold is centered. Below 0.5, passages favor one channel. Above 0.5, they favor the other. The wobble creates asymmetric morphogenesis — the two labyrinthine channels do not degrade symmetrically as entropy increases.

## Marching Cubes: Scalar Field to Mesh

The gyroid field is continuous — defined at every point in space. Rendering requires a discrete triangle mesh. Marching cubes converts the scalar field into geometry.

The algorithm divides space into a regular grid of cubes. At each cube vertex, the scalar field is evaluated. If the value is above the isosurface threshold, the vertex is "inside." If below, "outside." Each cube has 8 vertices, each either inside or outside, producing 2^8 = 256 possible configurations. Symmetry reduces these to 15 unique cases, each with a predefined triangulation.

```gdscript
# Marching cubes pseudocode:
func _generate_mesh(resolution: int, bounds: float) -> ArrayMesh:
    var vertices := PackedVector3Array()
    var step := bounds * 2.0 / float(resolution)

    for ix in range(resolution):
        for iy in range(resolution):
            for iz in range(resolution):
                var corner_values := _evaluate_cube_corners(ix, iy, iz, step)
                var cube_index := _classify_cube(corner_values, threshold)
                var triangles := MARCHING_CUBES_TABLE[cube_index]
                for tri in triangles:
                    var v := _interpolate_edge(tri, corner_values, step)
                    vertices.append(v)

    return _build_array_mesh(vertices)
```

**Edge interpolation** refines vertex placement. Rather than placing triangle vertices at cube edges, marching cubes linearly interpolates between the two cube vertices that straddle the isosurface, positioning the triangle vertex closer to the vertex whose field value is nearer the threshold. This produces smoother surfaces at the cost of one interpolation per edge crossing.

```gdscript
func _interpolate_edge(v1: Vector3, v2: Vector3,
                        val1: float, val2: float, threshold: float) -> Vector3:
    var t := (threshold - val1) / (val2 - val1)
    return v1.lerp(v2, t)
```

Resolution determines mesh quality. At resolution 32 (32^3 = 32,768 cubes), the mesh captures the gyroid's topology but with visible faceting. At resolution 64, surfaces are smoother. At resolution 128, the mesh approaches visual perfection but the generation cost scales cubically — 2 million cubes, each requiring 8 field evaluations and potentially multiple triangle emissions.

## The Entropy Gradient: Order to Chaos

At S = 0.0, the gyroid is a pristine mathematical surface. Its passages are uniform, its periodicity exact, its channels perfectly separated. This is maximum order — the surface encodes the trigonometric equation with no deviation.

At S = 0.5, noise begins to distort the passages. Some narrow. Some widen. The periodicity breaks locally while maintaining global structure. The surface becomes interesting — neither perfectly regular nor chaotically fragmented. This is the morphogenetic regime where form is actively emerging from the interplay between the underlying equation and the perturbing noise.

At S = 1.0, noise dominates. The gyroid equation is still present but buried under perturbation. Passages fragment. Isolated chambers appear. The two channel systems intersect where they shouldn't. Topology changes — holes open and close, handles form and break. The surface no longer tiles space periodically. It has become a unique, non-repeating form.

```gdscript
# Topology changes with entropy:
# S = 0.0: genus per unit cell is fixed (the gyroid's natural genus)
# S = 0.3: genus approximately preserved, minor perturbation
# S = 0.6: passages merge or split — genus changes
# S = 0.9: fragmented — many isolated components, high genus
# S = 1.0: maximum noise — chaotic surface, unpredictable topology
```

The entropy parameter is not metaphorical. It controls the literal Shannon entropy of the scalar field: at S = 0, the field is fully determined by the trigonometric equation (zero information content, maximum predictability). At S = 1, noise dominates the equation (maximum information content, minimum predictability). The morphogenesis — the emergence of form — happens in between, where the equation and the noise negotiate.

## Maximum Matching: Graph-Theoretic Morphogenesis

The map's second conceptual layer introduces maximum matching on general graphs. Given a graph G = (V, E), a matching M is a subset of edges where no vertex appears twice. The maximum matching is the largest such subset.

**Bipartite graphs** allow simple augmenting path algorithms. An augmenting path alternates between unmatched and matched edges, starting and ending at unmatched vertices. Flipping the matching status of every edge along the path increases the matching by one. Repeat until no augmenting path exists.

**General graphs** introduce odd cycles, which break augmenting path algorithms. A cycle of length 3, 5, or 7 has no perfect matching — one vertex is always left out. A naive algorithm encountering an odd cycle during augmenting path search enters an infinite loop, unable to match the remaining vertex.

**Edmonds' blossom algorithm** (1965) solves this by contracting odd cycles into single vertices. When the algorithm discovers an odd cycle (a "blossom"), it replaces the entire cycle with one super-vertex, solves the reduced graph, then expands the blossom back and threads the matching through it.

```gdscript
# Blossom contraction pseudocode:
func find_maximum_matching(graph: Dictionary) -> Array:
    var matching := {}
    while true:
        var path := find_augmenting_path(graph, matching)
        if path.is_empty():
            break
        augment_matching(matching, path)
    return matching

func find_augmenting_path(graph: Dictionary, matching: Dictionary) -> Array:
    # BFS from each unmatched vertex
    # If odd cycle detected: contract blossom, continue search
    # If augmenting path found: return it
    # If no path: return empty
    pass
```

The time complexity is O(V^2 * E), making it efficient for moderate graphs. The algorithm is significant because it solves a problem that simpler approaches cannot — odd cycles are not edge cases but structural features of most real-world graphs.

## Morphogenesis as Matching

The entropy_morphogenesis artifact visualizes matching as a morphogenetic process. Vertices are potential sites. Edges are possible connections. The matching algorithm selects a maximal compatible subset — structure crystallizing from a graph of possibilities.

The animation steps:
1. Display all vertices (potential) and edges (possibility)
2. Highlight augmenting path search — BFS wavefront expanding from unmatched vertices
3. When blossom detected: visually contract the odd cycle into a node
4. When augmenting path found: flip matched/unmatched status along the path
5. Repeat until maximum reached

The visual is topological morphogenesis: from a field of undifferentiated possibility, committed structure emerges through iterative constraint satisfaction. Each augmenting path increases the matching by one — one more pair committed, one more edge locked. The blossom contraction is the algorithm's act of shapeshifting: when a local configuration is impossible (odd cycle has no perfect matching), the algorithm transforms the problem's topology rather than giving up.

## The Gyroid-Matching Connection

Both the gyroid and the matching algorithm demonstrate the same principle: form emerges from constraint in a field. The gyroid's form emerges from the trigonometric constraint (the equation) perturbed by noise (entropy). The matching's form emerges from the compatibility constraint (no vertex twice) applied to a graph (the possibility field).

The entropy parameter S connects them. At S = 0, both systems are maximally constrained: the gyroid is a perfect minimal surface, the matching is a deterministic function of the graph. At S = 1, both systems are maximally disrupted: the gyroid fragments, the matching (on a random graph) becomes unpredictable. The morphogenetic regime — where entropy and constraint negotiate — is where both produce their most interesting forms.

The marching cubes algorithm is itself a kind of matching. Each cube's 8 vertices are classified inside or outside. The triangulation table matches each configuration to a set of triangles. The mesh emerges from 32,768 local matching decisions, each cube independently resolving its geometry, collectively producing a global surface. Local constraint satisfaction → global form emergence. This is morphogenesis at every scale.
