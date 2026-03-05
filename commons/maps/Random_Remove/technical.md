# A fully populated grid where stochastic selection decides what survives

Random_Definition established what randomness IS — incompressibility, pseudo-random generators, seeds, uniform distributions, entropy as accumulated disorder. Now: what randomness DOES. The 12x12 grid begins full. Every tile occupied. Maximum order, minimum entropy. Then the algorithm arrives — not to build, but to subtract. `randi_range()` picks an index. `remove_at()` erases it. `queue_free()` destroys the node. The cube vanishes. The gap remains. The grid becomes a landscape shaped by what was taken away.

Where Random_Definition filled an entropy jar to visualize disorder, Random_Remove empties a grid to demonstrate it. The direction reverses — from accumulation to deletion — but the thermodynamic arrow points the same way. Entropy increases. Order dissolves. The process does not run backward.

## The 8x8 Arena

The grid is 12x12 but the operational region is 8x8 — an inner arena bounded by a perimeter that remains intact. The boundary matters. It frames the destruction. Without edges, removal just scatters into void. With edges, the gaps register against the surrounding completeness. The perimeter is the control group. The interior is the experiment.

```gdscript
# Populate the 8x8 inner region with cubes
var cubes: Array[MeshInstance3D] = []

func populate_grid():
    for x in range(2, 10):
        for z in range(2, 10):
            var cube := MeshInstance3D.new()
            cube.mesh = BoxMesh.new()
            cube.position = Vector3(x * 1.1, 0.5, z * 1.1)
            cube.set_meta("grid_x", x)
            cube.set_meta("grid_z", z)
            add_child(cube)
            cubes.append(cube)
```

64 cubes. Each stores its grid coordinates as metadata — `grid_x` and `grid_z` — because once the array starts losing elements, position alone becomes unreliable for identification. The metadata is the cube's identity. The array is the population. Removal operates on the array; the scene tree follows.

## Random Index Selection

The simplest removal: pick a random index, delete whatever lives there.

```gdscript
var rng := RandomNumberGenerator.new()

func remove_one():
    if cubes.is_empty():
        return
    var idx := rng.randi_range(0, cubes.size() - 1)
    var target := cubes[idx]
    cubes.remove_at(idx)
    target.queue_free()
```

`randi_range()` selects an index uniformly from `[0, size - 1]`. `remove_at()` excises the element, shifting all subsequent elements down by one. `queue_free()` schedules the node for destruction at frame end. The cube disappears. The array contracts. The next call operates on a smaller population.

This is the atomic operation — everything else composes from it. The question becomes: how do you select which one?

## Removal Modes

The `remove_random` artifact parameterizes destruction. Four modes — range, column, row, all — each applying a different filter before the random selection occurs. The mode determines not whether randomness acts, but where it is permitted to act.

### Mode: All

No filter. Any cube in the array is a valid target. Uniform selection over the entire population.

```gdscript
func remove_mode_all(count: int):
    for i in range(count):
        if cubes.is_empty():
            break
        var idx := rng.randi_range(0, cubes.size() - 1)
        var target := cubes[idx]
        cubes.remove_at(idx)
        target.queue_free()
```

After many removals, survivors distribute roughly uniformly. No region favored, no region spared. The gaps form a pattern that is — by definition — incompressible. Evenly pockmarked, no clusters, no corridors. Random, in the Kolmogorov sense established in the previous map.

### Mode: Column

Filter the population to a single x-coordinate, then remove within that subset.

```gdscript
func remove_mode_column(col: int, count: int):
    var column_cubes := cubes.filter(
        func(c): return c.get_meta("grid_x") == col
    )
    for i in range(count):
        if column_cubes.is_empty():
            break
        var idx := rng.randi_range(0, column_cubes.size() - 1)
        var target := column_cubes[idx]
        column_cubes.remove_at(idx)
        cubes.erase(target)
        target.queue_free()
```

The `filter()` call constructs a subarray — only cubes whose `grid_x` matches the target column. Randomness operates within that column exclusively. The result is a vertical stripe of absence. The rest of the grid remains intact. The column is the constraint; randomness is the executioner within that constraint.

Note the dual removal: `column_cubes.remove_at(idx)` updates the filtered array so the loop does not revisit. `cubes.erase(target)` updates the master array so future calls reflect the deletion. Arrays in GDScript are copies at the moment of filtering — the filtered array and the master array diverge immediately. Keeping them consistent is the programmer's responsibility.

### Mode: Row

Identical logic, different axis. Filter by `grid_z` instead of `grid_x`.

```gdscript
func remove_mode_row(row: int, count: int):
    var row_cubes := cubes.filter(
        func(c): return c.get_meta("grid_z") == row
    )
    for i in range(count):
        if row_cubes.is_empty():
            break
        var idx := rng.randi_range(0, row_cubes.size() - 1)
        var target := row_cubes[idx]
        row_cubes.remove_at(idx)
        cubes.erase(target)
        target.queue_free()
```

A horizontal stripe of absence. Column and row modes produce orthogonal scars. Run both and the grid develops a crosshatch — structured destruction, randomness constrained to linear paths. The intersection of a removed column and a removed row is doubly empty, though "doubly" has no visual meaning. A gap is a gap. Absence does not stack.

### Mode: Range

Filter by distance from a center point. Only cubes within a radius are eligible for removal.

```gdscript
func remove_mode_range(center: Vector3, radius: float, count: int):
    var in_range := cubes.filter(func(c):
        return c.position.distance_to(center) <= radius
    )
    for i in range(count):
        if in_range.is_empty():
            break
        var idx := rng.randi_range(0, in_range.size() - 1)
        var target := in_range[idx]
        in_range.remove_at(idx)
        cubes.erase(target)
        target.queue_free()
```

Range mode produces circular voids. The `distance_to()` check draws an implicit circle on the grid plane — cubes inside are candidates, cubes outside are safe. The result is a roughly circular gap, edges ragged because the grid is discrete. Column and row modes are one-dimensional filters. Range is two-dimensional — it carves a region, not a line.

## Gaussian-Weighted Removal

Uniform removal treats every eligible cube with equal probability. Gaussian removal does not. Cubes closer to a center point are more likely to be selected. The probability decays with distance according to a bell curve.

```gdscript
func remove_gaussian(center: Vector3, sigma: float, count: int):
    for i in range(count):
        if cubes.is_empty():
            break
        # Weight each cube by Gaussian proximity to center
        var weights: Array[float] = []
        var total_weight := 0.0
        for cube in cubes:
            var dist := cube.position.distance_to(center)
            var w := exp(-dist * dist / (2.0 * sigma * sigma))
            weights.append(w)
            total_weight += w

        # Weighted random selection
        var roll := rng.randf() * total_weight
        var cumulative := 0.0
        for j in range(cubes.size()):
            cumulative += weights[j]
            if cumulative >= roll:
                var target := cubes[j]
                cubes.remove_at(j)
                target.queue_free()
                break
```

The Gaussian weight `exp(-d^2 / 2sigma^2)` peaks at the center and falls off symmetrically. `sigma` controls the width — small sigma concentrates destruction tightly; large sigma spreads it. The weighted selection accumulates weights into a cumulative distribution, then rolls a uniform random number against it. The cube whose cumulative bin contains the roll dies.

The center empties first. A crater forms. The edges retain most of their cubes. The destruction has a gradient — dense at the epicenter, sparse at the periphery. Run Gaussian removal enough times and the surviving pattern is a photographic negative of the bell curve. Absence encodes the distribution that produced it.

This connects directly to the entropy jar from Random_Definition. The jar showed entropy as accumulated particles. Here, entropy manifests as accumulated gaps. The Gaussian weight means E(S) rises faster in the middle of the grid than at the margins. The energy landscape has a basin of maximum destruction, and the basin's shape is the Gaussian.

## Random Walks on the Grid

A different kind of removal — not selecting targets from the population, but wandering through it. A random walk starts at some tile and steps to a neighbor at random. Each visited tile is marked — or removed.

```gdscript
func random_walk_remove(start: Vector2i, steps: int):
    var pos := start
    var directions := [
        Vector2i(1, 0), Vector2i(-1, 0),
        Vector2i(0, 1), Vector2i(0, -1)
    ]
    for step in range(steps):
        # Remove cube at current position
        var target_cube := find_cube_at(pos.x, pos.y)
        if target_cube:
            cubes.erase(target_cube)
            target_cube.queue_free()
        # Step in a random direction
        var dir := directions[rng.randi_range(0, 3)]
        pos += dir
        # Clamp to grid bounds
        pos.x = clampi(pos.x, 2, 9)
        pos.y = clampi(pos.y, 2, 9)

func find_cube_at(x: int, z: int) -> MeshInstance3D:
    for cube in cubes:
        if cube.get_meta("grid_x") == x and cube.get_meta("grid_z") == z:
            return cube
    return null
```

Four directions, equal probability — the drunkard's walk. Each step is independent of the previous. The walker has no memory, no preference, no goal. The path it traces is a connected sequence of removals — unlike the other modes, which scatter deletions across the grid, the walk carves a contiguous trail. The resulting gap is a worm-eaten tunnel, not a field of craters.

The walk's statistics matter. After N steps, expected displacement scales as sqrt(N). The walker revisits cleared tiles, doubles back, clusters. A 100-step walk covers far fewer than 100 unique tiles because the path self-intersects. Covering the entire 8x8 grid requires on the order of 64^2 = 4096 steps, not 64. Randomness explores by stumbling.

The walk also raises terrain — each visit increments a height value on the tile, producing ridges along frequently traversed paths. The height map is a histogram of visitation frequency. Tiles near the start accumulate more visits because the walk returns to its origin repeatedly. The resulting terrain peaks at the center and tapers outward — another manifestation of the Gaussian, this time emergent rather than imposed.

## Irreversibility

Remove a cube. Now put it back. Not the same cube — a new one, at the same position, with the same mesh. Is the grid restored?

No. The array order has changed. The indices have shifted. The PRNG has advanced its state by however many calls the removal consumed. Reconstructing the visual grid is trivial — place new cubes at the old positions. Reconstructing the computational state is impossible without rewinding the PRNG, which requires storing the entire sequence of draws. Incompressible. Random.

This is the thermodynamic arrow made computational. A full 8x8 grid has exactly one configuration — all 64 cubes present. A grid with 32 cubes removed has C(64, 32) configurations — approximately 1.83 x 10^18. The information about which configuration was selected lives only in the specific sequence of random draws. Destroy that sequence and the particular configuration becomes one unlabeled point in an astronomically large space. "All cubes present" is one sentence. "These 32 specific cubes absent" is a list.

The E(S) term in the QFEP framework tracks this. Each removal event increases E(S) — the system diffuses further from its ordered initial state. The process is monotonic under random deletion. No sequence of random removals can decrease E(S) without external intervention. The learner witnesses the second law in miniature: order is fragile, disorder is durable, and the arrow points one way.

## Hazards Demo: Absence as Gameplay

The `hazards_demo` artifact extends random removal into navigable consequence. The grid is a floor. Removed cubes are gaps. Gaps are falls. The learner — or a character — must traverse a grid riddled with stochastic holes.

```gdscript
func generate_hazard_floor(removal_fraction: float):
    populate_grid()
    var to_remove := int(cubes.size() * removal_fraction)
    remove_mode_all(to_remove)
    # Remaining cubes are walkable. Gaps are lethal.
```

At `removal_fraction = 0.1`, the floor is mostly intact — a few gaps to step around. At `0.3`, paths narrow. At `0.5`, navigation becomes a puzzle — connected components may isolate from each other, creating islands with no path between them. At `0.7`, the floor is more gap than surface.

The percolation threshold lurks here. For a square grid with random site removal, a critical fraction exists — approximately 0.593 — below which a connected path from one side to the other almost certainly exists, and above which it almost certainly does not. The `hazards_demo` does not compute percolation explicitly, but the learner experiences it. The transition is sharp — a phase transition in connectivity, driven entirely by the removal fraction.

This is where randomness acquires consequence. In `remove_random`, deletion is abstract — cubes vanish and the grid changes shape. In `hazards_demo`, deletion is spatial risk. The same stochastic process that sculpted an interesting pattern now sculpts a deadly one. The distribution is indifferent. What changes is the interpretation — and in a game engine, interpretation means physics, collision, traversal, survival.

## The Grid as Landscape of Absence

Stand on the perimeter. Look inward. The 8x8 region is no longer a uniform field. It is terrain — defined not by what rises but by what is missing. After column removal, vertical trenches. After row removal, horizontal channels. After range removal, circular craters. After Gaussian removal, a central basin tapering to intact edges. After a random walk, a worm trail. After uniform removal, a pockmarked plain.

Each mode leaves a signature. A forensic exercise: given a partially destroyed grid, infer the removal process that produced it. Uniform removal leaves no spatial correlation — each absence is independent. Gaussian clusters gaps near a center. Column creates vertical lines. The walk produces connected paths. The pattern is evidence. The absence is data.

This inverts the usual relationship between structure and information. A full grid compresses to one statement: "every tile present." A partially destroyed grid encodes the entire history of the removal process in its specific pattern of survivals and absences. Destruction increases information content. Entropy rises through erasure. The sculptor removes marble to reveal the statue. The algorithm removes cubes to reveal the distribution.

The `dark_sphere` sits in this landscape, pulsing with its deterministic sine-wave glow — unchanged by the removal around it. The grid mutates. The sphere persists. Randomness reshapes what is contingent. What is anchored endures.

## Array Manipulation in Practice

The mechanical details of array management during removal deserve explicit attention, because they are where bugs live.

```gdscript
# WRONG: removing during forward iteration
for i in range(cubes.size()):
    if should_remove(cubes[i]):
        cubes.remove_at(i)  # shifts all subsequent indices — skips next element

# RIGHT: iterate backward
for i in range(cubes.size() - 1, -1, -1):
    if should_remove(cubes[i]):
        cubes.remove_at(i)
        cubes[i].queue_free()

# RIGHT: collect targets first, remove after
var targets := cubes.filter(func(c): return should_remove(c))
for t in targets:
    cubes.erase(t)
    t.queue_free()
```

Forward iteration with removal is a classic off-by-one trap. Removing element `i` shifts element `i+1` into position `i`. The loop increments to `i+1`, skipping the shifted element. Backward iteration avoids this — removal at `i` only affects elements already processed. The collect-then-remove pattern sidesteps iteration order entirely by separating selection from deletion.

`queue_free()` defers destruction to frame end — other references remain valid during the current process step. `remove_child()` removes immediately. For removal during iteration, `queue_free()` is safer. But note the temporal gap: the node is gone from the array while still present in the scene tree. The array says absent. The scene tree says present-but-doomed.

## Possible Artifacts

**removal_heatmap** — Run the removal process 1000 times on a fresh grid each trial, recording which tiles are removed. Accumulate counts into a 2D histogram displayed as a color-mapped overlay on the 8x8 grid — hot cells removed frequently, cold cells rarely. For uniform removal, the heatmap is flat. For Gaussian removal, it peaks at the center. For column mode, a single vertical stripe glows. The empirical distribution of the removal process — the statistical fingerprint that a single run only hints at. Bridges deletion patterns back to Random_Definition.

**percolation_threshold_finder** — Incrementally increase the removal fraction from 0.0 to 1.0, testing after each step whether a connected path exists from left edge to right edge. Display the fraction at which connectivity breaks. Repeat many times and plot the distribution of critical fractions. The learner discovers the percolation threshold experimentally — a phase transition emerging from random removal.

**walk_density_terrain** — Execute a long random walk (thousands of steps) and render the visitation count at each tile as a height. Tiles visited often rise. Tiles never visited stay flat. The resulting terrain is a physical histogram of the walk's trajectory — peaked near the origin, decaying outward with the characteristic shape of a 2D diffusion kernel.

**entropy_counter** — Display a running count of C(64, K) — possible grid configurations after K removals. Starts at C(64, 0) = 1 when full. Grows explosively to maximum near K = 32. Contracts back to C(64, 64) = 1 when empty. Full and empty are both low-entropy. The middle is the wilderness.
