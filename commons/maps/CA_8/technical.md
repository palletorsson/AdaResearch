# Floating-point states replace binary switches across a spherical surface where edges dissolve and automata become continuous fields

CA_7 added probability to discrete rules. Cells still held integers — alive or dead, state 0 through state k — but the transition function rolled dice instead of consulting a lookup table. The noise blurred trajectories without blurring the states themselves. A cell at state 1 under 80% fire probability is still, at any given instant, definitively at state 1 or state 0. The coin lands. The value is crisp. CA_8 removes that crispness. Cells hold floating-point values between 0.0 and 1.0. The neighborhood is no longer a count of live neighbors but an integral over a continuous kernel. The transition function is no longer a step function but a smooth sigmoid. The automaton stops being a grid of switches and becomes a field — a surface of continuously varying intensity that flows, pools, and self-organizes into structures that look biological.

This is SmoothLife, introduced by Stephan Rafler in 2011. It generalizes Conway's Game of Life to continuous space and continuous state. The generalization is not cosmetic. Discrete CA produce blocky, lattice-aligned patterns because their dynamics are locked to the grid. SmoothLife produces round, flowing, isotropic patterns because its dynamics are locked to nothing — the kernel is circular, the transition is smooth, and the grid is merely a discretization artifact that fades as resolution increases. Wrapping the field onto a sphere eliminates the last structural artifact: edges. On a sphere, every point is interior. Every direction is equivalent. The automaton lives on a surface with no boundary, no corner, no preferred orientation.

## From Discrete Neighborhoods to Continuous Kernels

In a standard CA, the neighborhood is a fixed set of cells — the eight cells surrounding the center in a Moore neighborhood, the four in a von Neumann neighborhood. The neighbor sum is a count: how many of those cells are alive. SmoothLife replaces the count with a weighted integral over a continuous disk.

Two concentric regions define the kernel. The inner disk covers the cell itself — its state is the average field value within a small radius. The outer ring covers the neighborhood — its state is the average field value in the annular region between the inner radius and the outer radius.

```gdscript
@export var inner_radius: float = 4.0
@export var outer_radius: float = 12.0

func compute_inner_average(field: Array[float], cx: int, cy: int,
                            width: int, height: int) -> float:
    var total: float = 0.0
    var count: int = 0
    var ri_sq: float = inner_radius * inner_radius
    for dy in range(-int(inner_radius), int(inner_radius) + 1):
        for dx in range(-int(inner_radius), int(inner_radius) + 1):
            if dx * dx + dy * dy <= ri_sq:
                var nx: int = posmod(cx + dx, width)
                var ny: int = posmod(cy + dy, height)
                total += field[ny * width + nx]
                count += 1
    return total / float(count)

func compute_outer_average(field: Array[float], cx: int, cy: int,
                            width: int, height: int) -> float:
    var total: float = 0.0
    var count: int = 0
    var ri_sq: float = inner_radius * inner_radius
    var ro_sq: float = outer_radius * outer_radius
    for dy in range(-int(outer_radius), int(outer_radius) + 1):
        for dx in range(-int(outer_radius), int(outer_radius) + 1):
            var dist_sq: float = dx * dx + dy * dy
            if dist_sq > ri_sq and dist_sq <= ro_sq:
                var nx: int = posmod(cx + dx, width)
                var ny: int = posmod(cy + dy, height)
                total += field[ny * width + nx]
                count += 1
    return total / float(count)
```

The inner average replaces "current cell state." The outer average replaces "neighbor count." Both are real-valued. The inner disk smooths out the cell's own value over a spatial extent — the cell is not a point but a region. The outer ring integrates the surrounding field over a wider annulus. The ratio of outer to inner radius determines the spatial scale of interaction. A ratio of 3:1 (inner 4, outer 12) mirrors the approximate proportionality of Conway's rules, where a cell's fate depends on a ring of neighbors roughly three times its own diameter.

The `posmod` wrapping handles toroidal boundary conditions on a flat grid. On the sphere, this wrapping becomes unnecessary — the topology itself closes.

## The Sigmoid Transition Function

Conway's Game of Life uses a step function: a dead cell with exactly three live neighbors becomes alive; all other counts leave it dead. An alive cell with two or three live neighbors survives; all other counts kill it. The transition is discontinuous — a neighbor count of 2.99 and 3.01 produce identical results because the count is always integer.

SmoothLife replaces the step with a sigmoid. The transition function takes the inner average (cell state) and outer average (neighborhood density) and returns a new cell value between 0.0 and 1.0.

```gdscript
@export var birth_lo: float = 0.278
@export var birth_hi: float = 0.365
@export var death_lo: float = 0.267
@export var death_hi: float = 0.445
@export var sigmoid_width: float = 0.028

func smooth_sigmoid(x: float, center: float, width: float) -> float:
    return 1.0 / (1.0 + exp(-(x - center) / width))

func smooth_threshold(x: float, lo: float, hi: float, w: float) -> float:
    return smooth_sigmoid(x, lo, w) * (1.0 - smooth_sigmoid(x, hi, w))

func smooth_transition(inner_avg: float, outer_avg: float) -> float:
    var alive_threshold := smooth_threshold(outer_avg, death_lo, death_hi, sigmoid_width)
    var dead_threshold := smooth_threshold(outer_avg, birth_lo, birth_hi, sigmoid_width)
    # Interpolate between birth and survival based on current cell state
    return lerp(dead_threshold, alive_threshold, smooth_sigmoid(inner_avg, 0.5, sigmoid_width))
```

The `smooth_threshold` function creates a bump — high between `lo` and `hi`, low outside. It encodes the same logic as Conway's birth and survival counts but in continuous space. A neighborhood density between `birth_lo` and `birth_hi` promotes growth. A density between `death_lo` and `death_hi` permits survival. The `sigmoid_width` parameter controls how sharp the transition is. At width approaching zero, the sigmoid becomes a step function and SmoothLife degenerates to a discrete approximation. At larger widths, the transition zone broadens and the dynamics soften.

The four threshold parameters (`birth_lo`, `birth_hi`, `death_lo`, `death_hi`) are the continuous analogs of Conway's B3/S23 rule. Changing them produces different organism types — some parameter sets produce stable circular blobs, others produce gliders that slide across the field, others produce pulsating rings or chaotic froth. The parameter space is continuous, so the space of possible dynamics is uncountably larger than the space of discrete rule tables.

## Sphere Topology and the Elimination of Edges

Every flat-grid CA has a boundary problem. Cells at the edge have incomplete neighborhoods. Three common solutions exist: wrap into a torus (periodic), pad with dead cells (absorbing), or mirror at the edges (reflecting). Each introduces artifacts. Toroidal wrapping creates spatial periodicity. Absorbing boundaries swallow patterns. Reflecting boundaries create interference.

The sphere has none of these problems. A sphere is a closed surface with no boundary. Every point has a complete, symmetric neighborhood. There is no edge to wrap, absorb, or reflect. The topology itself solves the boundary condition.

```gdscript
@export var sphere_resolution: int = 128
@export var sphere_radius: float = 3.0

func lat_lon_to_index(lat: int, lon: int) -> int:
    var wrapped_lon: int = posmod(lon, sphere_resolution)
    var clamped_lat: int = clampi(lat, 0, sphere_resolution / 2 - 1)
    return clamped_lat * sphere_resolution + wrapped_lon

func sphere_neighbor_average(field: Array[float], lat: int, lon: int) -> float:
    var total: float = 0.0
    var weight: float = 0.0
    var ri_sq: float = inner_radius * inner_radius
    var ro_sq: float = outer_radius * outer_radius
    # Account for convergence of meridians near poles
    var lat_angle: float = PI * float(lat) / float(sphere_resolution / 2)
    var scale_at_lat: float = maxf(sin(lat_angle), 0.01)
    for dlat in range(-int(outer_radius), int(outer_radius) + 1):
        for dlon in range(-int(outer_radius), int(outer_radius) + 1):
            var adjusted_dlon: float = float(dlon) * scale_at_lat
            var dist_sq: float = float(dlat * dlat) + adjusted_dlon * adjusted_dlon
            if dist_sq > ri_sq and dist_sq <= ro_sq:
                var idx: int = lat_lon_to_index(lat + dlat, lon + dlon)
                total += field[idx]
                weight += 1.0
    return total / maxf(weight, 1.0)
```

The sphere introduces a geometric complication that flat grids avoid: the convergence of meridians. Near the equator, latitude and longitude cells are roughly square. Near the poles, longitude cells compress — many longitude values map to nearly the same point. The `scale_at_lat` factor adjusts the effective distance in the longitude direction based on the sine of the latitude angle. Without this correction, the kernel would stretch east-west near the poles, distorting the SmoothLife dynamics into latitude-dependent anisotropy.

The `ca_sphere` artifact renders this field directly onto a spherical mesh. Each vertex of the mesh corresponds to a cell in the latitude-longitude grid. The field value at each cell maps to a color — dark for 0.0, bright for 1.0, with a continuous gradient between. The sphere rotates slowly, allowing the learner to see the automaton from every angle. Patterns that form near the equator are round, as they would be on a flat grid with fine resolution. Patterns near the poles compress and distort, revealing the geometric tension between the flat field representation and the curved surface it lives on.

## SmoothLife Dynamics on the Sphere

Initialize the sphere field with random values between 0.0 and 1.0. The first few generations are chaotic — the random initial condition has no structure and every cell transitions independently. Within ten to twenty generations, local correlations emerge. Cells with similar values cluster. The clusters grow, merge, and begin to exhibit the characteristic SmoothLife behaviors: circular blobs that stabilize, tendrils that extend and retract, voids that open and close.

```gdscript
func initialize_random_field(total_cells: int) -> Array[float]:
    var field: Array[float] = []
    field.resize(total_cells)
    for i in range(total_cells):
        field[i] = randf()
    return field

func step_smoothlife(field: Array[float], width: int, height: int) -> Array[float]:
    var next: Array[float] = []
    next.resize(field.size())
    for y in range(height):
        for x in range(width):
            var inner: float = compute_inner_average(field, x, y, width, height)
            var outer: float = compute_outer_average(field, x, y, width, height)
            next[y * width + x] = smooth_transition(inner, outer)
    return next
```

On the flat grid, SmoothLife blobs eventually interact with edges. A blob that touches the boundary deforms — it flattens against an absorbing edge, wraps through a periodic edge, or reflects off a mirrored edge. On the sphere, blobs never encounter edges. They drift freely across the surface, interacting only with each other and with the curvature. A blob near the equator is round. A blob that drifts toward a pole elongates in the longitude direction as the coordinate system compresses — but the blob itself, as a physical structure on the surface, remains round. The distortion is in the representation, not the dynamics.

This distinction — between the mathematics of the automaton and the coordinates used to compute it — is the deeper lesson. The SmoothLife rules are defined in terms of distances and averages, not grid positions. The grid is a computational scaffold. On a flat grid, the scaffold's edges intrude on the dynamics. On a sphere, the scaffold has no edges, and the dynamics are pure.

## Continuity as a Limit of Discreteness

CA_5 introduced multi-state automata — cells with more than two values. A cell could hold 0, 1, 2, ..., k-1. With enough states, the grid appeared to vary continuously: gradients formed, waves propagated, excitable media cycled through values in smooth-looking arcs. But the states were still integers. The smoothness was visual, not mathematical. Zoom in far enough and the staircase appears.

SmoothLife removes the staircase. Cell values are floating-point numbers, and the transition function maps reals to reals through smooth sigmoids. The convergence is exact: as the grid resolution increases and the kernel radii scale accordingly, SmoothLife converges to a well-defined integro-differential equation. The cellular automaton becomes a PDE solver.

```gdscript
func convergence_test(resolutions: Array[int], steps: int) -> Array[Dictionary]:
    var results: Array[Dictionary] = []
    for res in resolutions:
        var width: int = res
        var height: int = res
        var field := initialize_seeded_field(width * height, 42)
        for s in range(steps):
            field = step_smoothlife(field, width, height)
        var mean_val: float = 0.0
        for v in field:
            mean_val += v
        mean_val /= field.size()
        results.append({
            "resolution": res,
            "mean_field": mean_val,
            "sample_center": field[(height / 2) * width + width / 2]
        })
    return results
```

Run SmoothLife at resolution 64, 128, 256, 512. At low resolution, the circular kernels are coarsely approximated — the inner disk is a rough polygon, the outer ring has visible steps. The dynamics are recognizably SmoothLife but exhibit grid-scale artifacts: blobs are slightly faceted, motion has preferred directions aligned with the grid axes. At higher resolution, the artifacts diminish. Blobs become smoother. Motion becomes more isotropic. The mean field value and the spatial statistics of the pattern converge toward stable values. The convergence is the hallmark of a well-posed continuum limit. Discrete automata do not converge — double the resolution of Conway's Game of Life and the dynamics change completely because the neighborhood structure changes. SmoothLife converges because its rules are defined in terms of distances, not grid positions.

This convergence places SmoothLife at the boundary between automata theory and continuum physics. It is both a cellular automaton (updated in discrete steps on a grid of cells) and a discretized PDE (converging to a smooth field equation as the grid refines). The boundary is not sharp. It is a spectrum, and SmoothLife sits exactly on it.

## Parameter Space and Organism Taxonomy

The four threshold parameters and the sigmoid width define a five-dimensional parameter space. Each point in this space corresponds to a different SmoothLife variant with different emergent dynamics. Some regions of the space are barren — the field decays to uniform 0.0 or saturates to uniform 1.0. Some regions produce static patterns. Others produce the characteristic SmoothLife organisms.

```gdscript
var smoothlife_presets: Dictionary = {
    "conway_analog": {
        "birth_lo": 0.278, "birth_hi": 0.365,
        "death_lo": 0.267, "death_hi": 0.445,
        "sigmoid_width": 0.028
    },
    "glider_rich": {
        "birth_lo": 0.257, "birth_hi": 0.336,
        "death_lo": 0.365, "death_hi": 0.549,
        "sigmoid_width": 0.014
    },
    "mitosis": {
        "birth_lo": 0.240, "birth_hi": 0.360,
        "death_lo": 0.120, "death_hi": 0.480,
        "sigmoid_width": 0.040
    }
}
```

The `conway_analog` preset produces dynamics that resemble Conway's Life: still lifes, oscillators, and occasional gliders. The `glider_rich` preset has a wider survival range and a narrower sigmoid, producing sharp-edged organisms that move coherently across the field. The `mitosis` preset has a broad death range and a wide sigmoid, producing blobs that grow until they pinch in half — binary fission on a computational surface.

On the sphere, these organisms interact without boundary interference. A glider-rich preset on a flat grid eventually fills the space with colliding gliders that pile up at edges. On the sphere, gliders circulate endlessly — a glider launched eastward returns from the west, having traversed the entire equator. If no collision intervenes, the glider orbits forever. The sphere permits dynamics that flat grids suppress.

## Curvature as a Physical Variable

The sphere is not just a convenient topology. Its curvature introduces real effects. Near the poles, surface area per latitude band shrinks. A SmoothLife organism of constant physical size occupies more cells near the poles than near the equator because each cell subtends less area. If kernel radii are specified in grid cells rather than physical distance, the effective interaction range changes with latitude.

```gdscript
func physical_kernel_radius(grid_radius: float, lat: int,
                             total_lat: int) -> float:
    var lat_angle: float = PI * float(lat) / float(total_lat)
    var cell_width: float = 2.0 * PI * sphere_radius * sin(lat_angle) / float(sphere_resolution)
    return grid_radius * cell_width
```

Correcting for this — scaling the kernel radius by the inverse of the cell width — maintains uniform physical dynamics across the sphere. Without correction, the poles act as a different medium: denser, with shorter-range interactions, favoring smaller organisms. With correction, the dynamics are uniform and the organism taxonomy is latitude-independent. The choice between corrected and uncorrected kernels is itself a modeling decision. Corrected kernels simulate a homogeneous surface. Uncorrected kernels simulate a surface with latitude-dependent physics — a kind of built-in gradient that concentrates activity near the equator and suppresses it near the poles.

## From Continuous Fields to Volume

SmoothLife on a sphere demonstrates two generalizations simultaneously: continuous state and curved topology. Together, they show that the core CA framework — local rules applied in parallel across a spatial domain — survives radical changes in both the state space and the geometry. The fundamental dynamic — local interaction producing global structure — persists.

CA_9 takes the geometric generalization further. Where CA_8 curved a 2D surface into a sphere, CA_9 extends the lattice into three dimensions. Cells fill a volume. Neighborhoods expand from 8 (2D Moore) to 26 (3D Moore). The combinatorial explosion is enormous, but the principle is unchanged: local rules, parallel application, emergent structure. The sphere eliminated edges by curving the surface. The 3D lattice introduces interiors — structures with insides that cannot be seen from outside. Navigation replaces observation. The learner walks through the automaton rather than looking down at it.

## Possible Artifacts

**flat_sphere_comparator** — The same SmoothLife parameters running simultaneously on a flat grid and on the sphere. The flat grid uses periodic (toroidal) boundary conditions. Both start from equivalent random initial conditions. Over dozens of generations, the flat version develops subtle axis-aligned artifacts and edge-interaction patterns. The sphere version produces isotropic dynamics with no preferred direction. A split view lets the learner toggle between the two, making the topological difference tangible in real time.

**parameter_explorer** — An interactive panel exposing the five SmoothLife parameters (birth_lo, birth_hi, death_lo, death_hi, sigmoid_width) as sliders. The sphere field updates live as parameters change. Preset buttons load known organism types — conway_analog, glider_rich, mitosis. The learner discovers the parameter space by dragging sliders and watching the sphere respond: from barren to teeming, from static blobs to circulating gliders, from orderly fission to chaotic froth.

**kernel_visualizer** — An overlay that renders the inner disk and outer ring of the SmoothLife kernel at any point on the sphere. Tap a cell and the kernel appears as a translucent circle-and-annulus projected onto the curved surface. Near the equator, the kernel is circular. Near the poles, the kernel distorts unless latitude correction is active. A toggle switches between corrected and uncorrected kernels, showing the geometric effect of curvature on interaction range.
