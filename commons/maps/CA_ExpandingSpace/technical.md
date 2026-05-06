# Cells extend their gaze beyond nearest neighbors into widening shells where overlapping influence zones produce branching growth and interference corridors

CA_5 widened the state space. Cells graduated from binary switches to multi-valued dials, carrying intensity, decay, memory. But every rule still operated on the same eight neighbors — the Moore neighborhood, one step in each direction. The boundary of influence was fixed at radius 1. CA_6 breaks that constraint. The neighborhood radius becomes a variable. Cells now consult not just their immediate ring but second, third, arbitrary rings outward. The spatial horizon of each cell expands, and the character of emergence changes with it.

State depth and spatial reach are orthogonal axes. CA_5 stretched the first. CA_6 stretches the second. A cell with eight neighbors and 256 states lives in a different dynamical regime than a cell with 48 neighbors and 256 states. The rule table is the same structure — current state plus neighborhood context yields next state — but the context itself is richer. More neighbors means more information per update. More information per update means faster propagation, smoother gradients, and structures that require long-range coordination to form.

The three artifacts in this map demonstrate extended neighborhoods in distinct regimes. The `cellular_automata_3d_tree` grows branching structures layer by layer, pruning cells based on neighbor counts across a 2D shell at each height. The `crossway_ca` tiles a walkable surface with row-by-row rules where each cell's fate depends on a wrapped neighborhood that reaches across the grid. The `decaying_bridge` extends the influence zone radially — cells within a radius of the player decay, cells outside that radius regrow based on healthy-neighbor counts. Three different geometries of reach. Three different emergent forms.

## The Extended Moore Neighborhood

The standard Moore neighborhood at radius 1 contains 8 cells: the 3x3 square minus the center. Extend the radius to r, and the neighborhood becomes the (2r+1)x(2r+1) square minus the center. The count follows a clean formula:

```
neighbor_count = (2r + 1)^2 - 1
```

At radius 1: 8 neighbors. Radius 2: 24. Radius 3: 48. Radius 4: 80. The count grows quadratically with r. Each increment adds a full ring of cells around the previous neighborhood.

```gdscript
func get_extended_neighbors(cx: int, cy: int, radius: int) -> Array:
    var neighbors := []
    for dx in range(-radius, radius + 1):
        for dy in range(-radius, radius + 1):
            if dx == 0 and dy == 0:
                continue
            var nx := (cx + dx + grid_width) % grid_width
            var ny := (cy + dy + grid_height) % grid_height
            neighbors.append(Vector2i(nx, ny))
    return neighbors
```

The modular wrapping — `(cx + dx + grid_width) % grid_width` — makes the grid toroidal. Cells at the left edge see cells at the right edge. The torus eliminates boundary asymmetry. Every cell has exactly the same neighborhood size regardless of position.

The quadratic growth has computational consequences. A rule scanning 80 neighbors per cell is ten times more expensive than one scanning 8 — and the grid has not grown at all. Extended neighborhoods trade cost for informational richness.

In 3D the scaling is cubic. A 3D Moore neighborhood at radius r contains `(2r+1)^3 - 1` cells. Radius 1: 26. Radius 2: 124. Radius 3: 342. The `cellular_automata_3d_tree` operates in this regime, though it restricts its pruning checks to a 2D slice at each level rather than a full volumetric shell. The restriction is deliberate — the tree grows vertically, one layer at a time, and the pruning logic asks "how many neighbors does this cell have in its own horizontal plane?" rather than "how many neighbors does this cell have in the full 3D volume?" The dimensionality of the neighborhood is a design choice, not a fixed property of the grid.

## Branching Growth: The 3D Tree

The `cellular_automata_3d_tree` builds a tree-shaped structure by stacking 2D layers. Each layer starts as a filled square, then a CA-like pruning pass removes cells based on local density, edge proximity, and randomness. The result is an organic branching form that emerges from simple per-cell rules applied iteratively.

Growth proceeds in three phases. Levels 0 through 7 form the trunk — solid square layers at `base_size` width with no pruning. Levels 8 through 10 expand: each layer is one cell wider than the last, and pruning begins. Levels 11 through 14 hold steady at maximum width with continued pruning. Levels 15 through 18 shrink, narrowing the canopy to a point. The phase logic is explicit:

```gdscript
func grow_next_level():
    if current_level >= 8 and current_level <= 10:
        var size = (base_size + 1) + (current_level - 8)
        create_square_layer(current_level, size)
        apply_ca_pruning(current_level, size)
        current_level += 1
    elif current_level >= 11 and current_level <= 14:
        var size = base_size + 3
        create_square_layer(current_level, size)
        apply_ca_pruning(current_level, size)
        current_level += 1
    elif current_level >= 15 and current_level <= 18:
        var shrink_step = current_level - 15
        var size = (base_size + 3) - (shrink_step * 2)
        if size > 0:
            create_square_layer(current_level, size)
            apply_ca_pruning(current_level, size)
        current_level += 1
    else:
        is_growing = false
```

Three phases, three behaviors, one growth loop. The envelope — the outer shape of the tree — is hardcoded. The interior detail is emergent. The pruning pass decides which cells survive within each layer, and that decision depends on the extended neighborhood.

The pruning function `count_neighbors_2d` scans the 8 immediate neighbors in the horizontal plane:

```gdscript
func count_neighbors_2d(x: int, level: int, z: int, size: int) -> int:
    var count = 0
    for dx in [-1, 0, 1]:
        for dz in [-1, 0, 1]:
            if dx == 0 and dz == 0: continue
            var neighbor_pos = Vector3i(x + dx, level, z + dz)
            if grid.has(neighbor_pos):
                count += 1
    return count
```

This is a radius-1 Moore neighborhood restricted to 2D. But the pruning rules layer multiple conditions on top of that count, creating an effective influence zone much wider than the raw neighbor scan. Edge pruning checks the cell's Euclidean distance from the layer center. A cell at `edge_factor > 0.7` — 70% of the way from center to corner — faces a 40% removal chance. That distance calculation implicitly makes the pruning aware of the cell's global position within the layer, not just its local neighborhood. The combination of local density checks and global distance checks produces an effective neighborhood that blends local and non-local information.

The center is protected unconditionally:

```gdscript
if abs(x - center) < 1.0 and abs(z - center) < 1.0:
    should_remove = false
```

The trunk must not break. No matter how aggressive the pruning, cells within one unit of the center survive. This is a topological constraint disguised as a conditional — the tree remains connected because the center column is indestructible. Without it, pruning could sever the structure at a narrow waist, producing disconnected floating clusters rather than a branching form.

The visual encoding uses a height-mapped gradient. Low levels sample the gradient near 0.0 — brown, trunk-like. High levels sample near 1.0 — green, leaf-like. The transition is continuous:

```gdscript
var color_ratio = float(level) / 18.0
var col = gradient.sample(color_ratio)
mm.set_instance_color(idx, col)
```

The gradient does double duty. It communicates structure (trunk versus canopy) and it communicates age (older layers are lower, younger layers are higher). A single visual parameter encodes two distinct properties because height correlates with both.

## Interference on the Crossway

The `crossway_ca` lays a 10-by-16 grid flat on the ground. Unlike the tree, which grows vertically one layer at a time, the crossway operates row by row across a horizontal surface. Each row has its own rule — a random integer from 0 to 255, encoding a binary function over the 8-neighbor Moore neighborhood.

```gdscript
func initialize_rules():
    rules.clear()
    rules.resize(grid_height)
    for i in range(grid_height):
        rules[i] = randi() % 256
```

Sixteen rows, sixteen rules. The grid is a stack of one-dimensional rule applications laid side by side. Each row's rule determines which neighbor counts produce live cells:

```gdscript
func update_bridge():
    if current_row_to_change < grid_height:
        for i in range(grid_width):
            var neighbors = count_neighbors(i, current_row_to_change)
            var rule = rules[current_row_to_change]
            if (rule >> neighbors) & 1:
                current_gen[i][current_row_to_change] = 1
            else:
                current_gen[i][current_row_to_change] = 0
        current_row_to_change += 1
```

The bit-shift `(rule >> neighbors) & 1` is compact. It treats the rule integer as a lookup table: bit position `n` encodes whether a cell with `n` neighbors lives or dies. A rule of 255 (all bits set) keeps every cell alive regardless of neighbors. A rule of 0 kills everything. A rule of 12 (binary `00001100`) activates cells with exactly 2 or 3 neighbors — Conway-like. The crossway tiles multiple such rules in adjacent rows, and the boundaries between rows produce interference.

The neighbor count function wraps toroidally:

```gdscript
func count_neighbors(x, y):
    var count = 0
    for i in range(-1, 2):
        for j in range(-1, 2):
            if i == 0 and j == 0:
                continue
            var nx = (x + i + grid_width) % grid_width
            var ny = (y + j + grid_height) % grid_height
            if current_gen[nx][ny] == 1:
                count += 1
    return count
```

The wrapping is what creates extended influence. A cell in row 5 reads from rows 4 and 6. Row 4 operates under one rule; row 6 operates under another. The cell's fate depends on the output of rules it does not share. At the boundary between two rows with conflicting rules, neither rule dominates cleanly. The resulting pattern is neither one rule nor the other but an interference zone — a spatial region where overlapping influence zones compete.

Every ten generations the rules re-randomize. The crossway is not stable. It cycles through configurations, rebuilding its pattern from scratch periodically. The visual effect on the walkable surface is a shifting terrain of solid and absent cells — a bridge that rearranges itself underfoot.

## Decay With Extended Reach

The `decaying_bridge` uses a continuous health value per cell — a float from 0.0 to 1.0 rather than the discrete integer states of CA_5. But the core mechanic is still neighborhood-dependent: cells decay when the player is within `decay_radius`, and cells regrow based on healthy-neighbor count.

```gdscript
@export var decay_radius: float = 2.0

func _update_simulation(dt):
    for coord in grid.keys():
        var pos = mesh_instances[coord].position
        var dist = pos.distance_to(local_player_pos)

        if dist < decay_radius:
            grid[coord] = max(0.0, grid[coord] - decay_speed * dt * 5.0)
        else:
            var neighbors = _count_healthy_neighbors(coord)
            if neighbors > 0:
                grid[coord] = min(1.0, grid[coord] + regrow_speed * dt * 0.1 * neighbors)
```

The `decay_radius` is the player's destructive neighborhood. It is not a grid-aligned Moore radius but a Euclidean distance check — circular, not square. Any cell within 2.0 units of the player's local position loses health. The player is an agent of decay, carving a circular hole in the bridge wherever they stand.

Regrowth depends on the von Neumann neighborhood — four cardinal neighbors:

```gdscript
func _count_healthy_neighbors(coord: Vector2i) -> int:
    var count = 0
    var dirs = [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]
    for d in dirs:
        var n = coord + d
        if grid.has(n) and grid[n] > 0.5:
            count += 1
    return count
```

Four neighbors, not eight. The threshold for "healthy" is 0.5 — a cell must be at least half health to count. The regrowth rate scales linearly with healthy-neighbor count: zero healthy neighbors means zero regrowth. Four healthy neighbors means maximum regrowth. Isolated cells starve. Connected cells heal.

The asymmetry is intentional. Decay is radius-based and unconditional — proximity to the player is sufficient. Regrowth is neighbor-based and conditional — connectivity to healthy cells is required. The player destroys by presence. The bridge rebuilds by topology. Small holes heal quickly (surrounded cells have many healthy neighbors). Large holes heal slowly (only edge cells touch healthy neighbors). A sufficiently aggressive player can outrun the healing and destroy the bridge entirely.

The visual encoding maps health to color and transparency:

```gdscript
var mat = StandardMaterial3D.new()
mat.albedo_color = color_dead.lerp(color_healthy, health)
if health < 0.1:
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.albedo_color.a = health * 10.0
```

Full health renders as bright green. Zero health renders as fully transparent. The `lerp` produces a continuous gradient; below 10% health, transparency kicks in, fading the cell out entirely. Collision also responds to health — cells below 20% disable their collision shape:

```gdscript
if health < 0.2:
    col.disabled = true
else:
    col.disabled = false
```

The bridge is not just visually decaying. It is structurally decaying. The player can fall through dead cells. The CA rule is not cosmetic — it governs whether the geometry is walkable.

## Neighborhood Radius as Information Horizon

The radius controls how far information travels in a single generation. At radius 1, a signal — a newly activated cell — moves one cell per step. At radius 3, the same signal can influence cells three steps away in a single generation. The effective propagation speed is the radius.

This has profound consequences for pattern formation. At radius 1, structures form slowly and locally. Fine-grained textures dominate because correlations only extend one cell. At radius 3, structures form faster and span larger regions. The automaton's texture coarsens — patterns become smoother, features become broader. The same rule at different radii produces qualitatively different dynamics.

The `cellular_automata_3d_tree` demonstrates this implicitly. Its pruning combines a local neighbor count (radius 1) with a global edge-distance check (effectively infinite radius, since it compares against the layer center). The local check creates fine-grained texture — individual cells survive or die based on their immediate surroundings. The global check creates large-scale shape — the tree is round, not square, because corners are preferentially pruned. Two scales of neighborhood, two scales of structure.

The `crossway_ca` demonstrates interference between radius-1 neighborhoods operating under different rules. The radius is small, but rule heterogeneity creates effective long-range interaction. A pattern generated by one rule in row 5 influences neighbor counts in rows 4 and 6, which operate under different rules. The influence cascades across the grid indirectly.

## Rule Table Explosion

Expanding the neighborhood also expands the rule table. For a binary automaton with a Moore neighborhood at radius r, the number of possible neighborhood configurations is:

```
2^((2r+1)^2 - 1)
```

At radius 1: `2^8 = 256` configurations. A complete rule table has 256 entries — manageable. At radius 2: `2^24 = 16,777,216` configurations. At radius 3: `2^48`, a number so large that enumerating the rule table is impractical. No learner will explore that space exhaustively. No researcher will either.

This is why totalistic rules (from CA_4) become essential at extended radii. A totalistic rule does not care which neighbors are alive — only how many. The number of possible sums for a neighborhood of n cells ranges from 0 to n. At radius 2, that is 0 to 24 — twenty-five possible inputs instead of sixteen million. The compression is enormous. Totalistic rules at extended radii are the only computationally tractable approach for large neighborhoods.

```gdscript
func apply_totalistic_extended(cx: int, cy: int, radius: int) -> int:
    var alive_count := 0
    for dx in range(-radius, radius + 1):
        for dy in range(-radius, radius + 1):
            if dx == 0 and dy == 0:
                continue
            var nx := (cx + dx + grid_width) % grid_width
            var ny := (cy + dy + grid_height) % grid_height
            alive_count += grid[ny * grid_width + nx]
    # Totalistic threshold rule
    var max_neighbors := (2 * radius + 1) * (2 * radius + 1) - 1
    var density := float(alive_count) / float(max_neighbors)
    if density > 0.4 and density < 0.7:
        return 1
    return 0
```

The density threshold replaces the per-configuration lookup. The rule asks "what fraction of neighbors are alive?" and applies a continuous threshold. The same density-based rule at different radii produces different dynamics because the averaging region changes size. Larger radius means more averaging, smoother fields, slower pattern evolution.

## The Locality Spectrum

Classical CA theory defines cellular automata by local rules — each cell updates based on a finite, fixed neighborhood. Extending the radius does not violate locality; the neighborhood is still finite. But the effective behavior shifts. At radius 1, the automaton feels local: patterns are granular, propagation is slow, structures are small. At radius 10, the automaton feels global: patterns are smooth, propagation is fast, structures span the grid.

The question is where locality ends and globality begins. A radius-3 neighborhood on a 100x100 grid consults 48 of 10,000 cells — less than 0.5%. On a 10x10 grid, the same radius consults 48 of 100 cells — nearly half. Locality depends on the ratio of neighborhood size to grid size, not the absolute radius.

The `decaying_bridge` makes this tangible. A `decay_radius` of 2.0 on a 20-by-4 grid covers a significant fraction of the bridge width. The same radius on a 200-by-40 grid would be negligible. The parameter has not changed. The context has.

## Possible Artifacts

**neighborhood_radius_slider** — A flat grid running a single totalistic rule with an adjustable radius parameter. At radius 1 the pattern is grainy and slow-moving. Slide to radius 2 and the features coarsen, the wavefronts widen, the propagation accelerates. Radius 3 produces broad smooth regions with slow undulation. The same rule, the same grid, the same initial seed — only the radius changes. The learner watches the transition from granular to smooth in real time and builds intuition for what "extending the neighborhood" means dynamically.

**influence_zone_visualizer** — Highlights the neighborhood of a selected cell in real time. Tap a cell and see its radius-1 Moore neighborhood outlined. Increase the radius and watch the highlighted region expand quadratically. Overlay the neighborhoods of two adjacent cells to see their overlap zone — the set of cells that both consult. At radius 1, the overlap is small. At radius 3, most of their neighborhoods overlap. The overlap fraction quantifies how correlated two cells' updates are and explains why extended neighborhoods produce smoother patterns.

**3d_shell_explorer** — A volumetric visualization of the 3D Moore neighborhood at increasing radii. At radius 1, the shell contains 26 cells arranged in a cube. At radius 2, the shell is the outer ring of a 5x5x5 cube — 98 cells. The learner rotates the shell, sees its geometry, counts its members, and connects the formula `(2r+1)^3 - 1` to spatial reality. Pairs with the `cellular_automata_3d_tree` to show why 3D neighborhoods produce qualitatively different branching than 2D pruning applied level by level.
