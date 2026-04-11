# Neighbors collapse into a single count and the hexagonal lattice proves the grid was never the point

CA_3 enumerated 256 elementary rules by encoding each three-cell neighborhood as a binary index — left, center, right, each distinguished, each carrying positional meaning. That specificity is expensive. Move to two dimensions with a Moore neighborhood and the number of distinct configurations explodes: 2^9 = 512 for binary states, and every additional state multiplies it further. Totalistic rules answer this with a compression: stop distinguishing which neighbor is alive and start counting how many. Nine cells in a Moore neighborhood reduce to a single integer between 0 and 8. The rule table shrinks. The behavior does not.

Conway's Game of Life was already totalistic — B3/S23 depends on neighbor count, not neighbor arrangement. But Life is one rule in an enormous family. Totalistic rules formalize the entire family. The cell does not know which direction the influence arrived from. It only knows the sum. Direction is forgotten. Quantity persists. And from that compressed signal, complex behavior still emerges.

## The Totalistic Rule Table

An elementary CA rule maps 8 distinct neighborhood patterns to outputs — an 8-bit number, 256 rules total. A totalistic rule on the same 1D three-cell neighborhood maps differently. Three binary neighbors produce sums from 0 to 3 (when the center cell is included) or 0 to 2 (when excluded). Include the cell's own state and the sum ranges from 0 to 3. The rule table has 4 entries instead of 8.

```gdscript
func totalistic_1d(rule_table: Array[int], left: int, center: int, right: int) -> int:
    var total: int = left + center + right
    return rule_table[total]
```

Three cells, three values, one sum. The lookup table has `k * n + 1` entries for k states and n neighbors — not `k^n`. For binary 1D: `2 * 3 + 1 = 7` possible sums when counting center, versus `2^3 = 8` general patterns. The savings are modest in one dimension. In two dimensions the gap widens dramatically.

A Moore neighborhood with binary states has 2^8 = 256 configurations per cell state, 512 total entries in the general rule table. The totalistic version: 0 through 8 neighbors, times 2 cell states, 18 entries. From 512 to 18. For k states and r neighbors, the general table has `k^(k^r)` rules; the totalistic table has `k^(k * r + 1)`. The exponent drops from exponential to linear.

```gdscript
const MOORE: Array[Vector2i] = [
    Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
    Vector2i(-1,  0),                  Vector2i(1,  0),
    Vector2i(-1,  1), Vector2i(0,  1), Vector2i(1,  1),
]

func totalistic_2d(cell_state: int, grid: Array[Array], x: int, y: int,
                   birth: Array[int], survival: Array[int]) -> int:
    var count: int = 0
    for offset in MOORE:
        var nx: int = posmod(x + offset.x, width)
        var ny: int = posmod(y + offset.y, height)
        count += grid[ny][nx]

    if cell_state == 0:
        return 1 if count in birth else 0
    else:
        return 1 if count in survival else 0
```

B3/S23 is one point in this space. B36/S23 — HighLife — differs by a single birth entry. B1357/S1357 — Replicator — uses an entirely different set. Each variant produces a distinct universe. The totalistic framework makes these variants navigable: instead of searching 2^512 possible rules, the space reduces to combinations of birth and survival thresholds.

## Exploring the B/S Landscape

The birth/survival notation makes the totalistic rule space enumerable. For a Moore neighborhood, the birth set is any subset of {0, 1, 2, 3, 4, 5, 6, 7, 8} and the survival set is likewise any subset. That gives 2^9 * 2^9 = 262,144 possible rules — a large number, but astronomically smaller than the general rule space.

```gdscript
func encode_bs_rule(birth: Array[int], survival: Array[int]) -> int:
    var code: int = 0
    for b in birth:
        code |= (1 << b)
    for s in survival:
        code |= (1 << (s + 9))
    return code

func decode_bs_rule(code: int) -> Dictionary:
    var birth: Array[int] = []
    var survival: Array[int] = []
    for i in 9:
        if code & (1 << i):
            birth.append(i)
        if code & (1 << (i + 9)):
            survival.append(i)
    return {"birth": birth, "survival": survival}
```

An 18-bit integer encodes any totalistic rule on a Moore neighborhood. The lower 9 bits are birth thresholds; the upper 9 are survival thresholds. This encoding makes it possible to iterate over the entire space programmatically — testing each rule, recording its population dynamics, classifying its behavior.

Some regions of the space are predictable. B0 rules (birth with zero neighbors) fill the grid immediately — every dead cell surrounded by dead cells is born. S8 rules (survival only with all 8 neighbors alive) kill almost everything. The interesting rules cluster in the middle: moderate birth thresholds, moderate survival ranges. B3/S23 sits in this band. So does B36/S23 (HighLife) and B368/S245 (Morley).

Interesting behavior is not uniformly distributed in rule space. It concentrates where birth and survival conditions are neither too permissive nor too restrictive — the same edge-of-chaos principle that CA_2 identified in Life's dynamics, now visible across the entire totalistic landscape.

## What Totalistic Compression Discards

The compression has a cost. Totalistic rules cannot distinguish a neighbor configuration of `[1,0,0,1,0,0,0,0]` from `[0,0,0,0,1,0,0,1]` — both sum to 2. Any rule that needs to know where the live neighbors sit, not just how many, falls outside the totalistic family.

Consider a directional rule: a cell is born only if it has exactly 2 live neighbors and both are adjacent to each other. This rule requires positional information. The totalistic version sees "2 neighbors" and cannot distinguish clustered from scattered. The rule is inexpressible.

```gdscript
# This rule is NOT totalistic — it requires spatial layout
func directional_rule(neighbors: Array[int]) -> int:
    var count: int = 0
    for n in neighbors:
        count += n
    if count != 2:
        return 0
    # Check if both live neighbors are adjacent to each other
    # This requires knowing WHICH cells are alive, not just the count
    for i in neighbors.size():
        if neighbors[i] == 1 and neighbors[(i + 1) % neighbors.size()] == 1:
            return 1
    return 0
```

The totalistic assumption — that the sum carries sufficient information — is an assertion about what matters. The spatial arrangement of neighbors is noise; the aggregate is signal. Population pressure depends on density, not on which specific neighbors are present. Heat diffusion depends on the average surrounding temperature.

But anisotropic processes — crystal growth along preferred axes, fluid flow with directional viscosity — require the positional data that totalistic rules erase. The compression is not universal. It is a modeling choice.

Life's richness despite that compression suggests that for a wide class of phenomena, counting is enough. The cell's ignorance of direction does not impoverish the dynamics. It focuses them.

## The Hexagonal Lattice

A square grid is a choice, not a requirement. Any tessellation that tiles the plane and defines neighbor relationships supports a cellular automaton. The hexagonal lattice is the natural second option: regular hexagons tile the plane with each cell touching exactly 6 neighbors, all at equal distance.

```gdscript
# Hexagonal neighbor offsets depend on row parity
# Even rows and odd rows have different diagonal offsets
func hex_neighbors(x: int, y: int) -> Array[Vector2i]:
    if y % 2 == 0:
        return [
            Vector2i(-1, 0), Vector2i(1, 0),     # left, right
            Vector2i(-1, -1), Vector2i(0, -1),    # upper-left, upper-right
            Vector2i(-1, 1), Vector2i(0, 1),      # lower-left, lower-right
        ]
    else:
        return [
            Vector2i(-1, 0), Vector2i(1, 0),     # left, right
            Vector2i(0, -1), Vector2i(1, -1),     # upper-left, upper-right
            Vector2i(0, 1), Vector2i(1, 1),       # lower-left, lower-right
        ]
```

The offset-coordinate system encodes hexagons in a rectangular array with alternating row offsets. Even rows shift left; odd rows shift right. The staggering is a storage convention — the geometry underneath is six equidistant neighbors per cell.

Six neighbors instead of eight changes the dynamics fundamentally. The maximum neighbor count drops from 8 to 6. Birth and survival thresholds that produced interesting behavior on a square grid may produce death or explosion on a hexagonal one. B3/S23 on a hexagonal lattice is not the same universe as B3/S23 on a square lattice — the "3" in B3 means something different when the maximum is 6 instead of 8.

The proportional interpretation matters. Three out of eight neighbors is 37.5%. Three out of six is 50%. A hexagonal B3 birth rule fires at a higher proportional threshold than its square counterpart. To replicate the proportional dynamics of square B3/S23, the hexagonal rule needs something closer to B2/S12 — birth at 33%, survival at 17-33%. The threshold is an integer, but its meaning is the ratio of live neighbors to total neighbors.

```gdscript
func proportional_threshold(count: int, total_neighbors: int) -> float:
    return float(count) / float(total_neighbors)

# Square B3:  3/8 = 0.375
# Hex B3:     3/6 = 0.500
# Hex B2:     2/6 = 0.333  (closer to square B3 proportionally)
```

This proportional view connects cellular automata to percolation theory. The critical density at which connected clusters span the grid depends on lattice geometry. Square lattices percolate around 0.5; hexagonal lattices around 0.6527. Totalistic rules that produce spanning structures on one lattice may fail to percolate on another.

```gdscript
func hex_life_step(grid: Array[Array], w: int, h: int,
                   birth: Array[int], survival: Array[int]) -> Array[Array]:
    var next: Array[Array] = []
    next.resize(h)
    for y in h:
        next[y] = []
        next[y].resize(w)
        for x in w:
            var neighbors := hex_neighbors(x, y)
            var count: int = 0
            for offset in neighbors:
                var nx: int = posmod(x + offset.x, w)
                var ny: int = posmod(y + offset.y, h)
                count += grid[ny][nx]

            if grid[y][x] == 0:
                next[y][x] = 1 if count in birth else 0
            else:
                next[y][x] = 1 if count in survival else 0
    return next
```

The step function is structurally identical to the square-grid version. The only difference is the neighbor list. The rule logic — totalistic birth/survival — is unchanged. The automaton does not care about the shape of its cells. It cares about the graph of connections between them.

## Geometry as Parameter

The hexagonal lattice reveals a deeper point. The square grid has two kinds of neighbors: cardinal (shared edge, distance 1) and diagonal (shared corner, distance ~1.414). The Moore neighborhood treats both equally, but they are not geometrically equal. A diagonal neighbor is farther away. The square grid's isotropy is approximate.

The hexagonal grid has one kind of neighbor. All six share an edge. All six are equidistant. The lattice is isotropic — no preferred direction, no diagonal artifacts. Growth patterns on hexagonal grids tend toward circular rather than diamond or square shapes.

```gdscript
# On a square grid: neighbor distances vary
# Cardinal: 1.0   Diagonal: ~1.414
# On a hex grid: all neighbors equidistant
# Every neighbor shares an edge at distance 1.0

func neighbor_distance_square(offset: Vector2i) -> float:
    return Vector2(offset.x, offset.y).length()
    # (1,0) -> 1.0    (1,1) -> 1.414

func neighbor_distance_hex() -> float:
    return 1.0  # All neighbors equidistant
```

This isotropy matters for modeling physical processes. Diffusion on a square grid produces diamond-shaped wavefronts because diagonal information travels faster (one step covers more ground). Diffusion on a hexagonal grid produces rounder wavefronts that better approximate continuous diffusion. The geometry shapes the physics. Choosing a grid is choosing a bias.

The `hexagon_ca_vr` artifact places this choice in the learner's hands — literally. A hexagonal Life-like automaton runs on a lattice the learner can observe from within VR. The cells are physical hexagonal tiles. The six-neighbor structure is visible as geometry, not as an abstract offset table. Walking across the lattice, the equal spacing is felt. The absence of diagonal ambiguity is experienced rather than explained.

## Population Dynamics and the Growth Network

Totalistic rules produce population curves — the count of live cells over time. These curves are signatures. A rule that kills everything produces a curve that drops to zero. A rule that fills the grid produces a curve that saturates. An interesting rule produces a curve that fluctuates — rising, falling, finding temporary equilibria, breaking them.

```gdscript
var population_history: Array[int] = []

func record_population(grid: Array[Array], w: int, h: int) -> void:
    var count: int = 0
    for y in h:
        for x in w:
            count += grid[y][x]
    population_history.append(count)
```

The `ca_growth_network` artifact tracks these population dynamics. Each generation produces a data point. The accumulating curve reveals the automaton's regime: exponential growth (supercritical birth rate), exponential decay (subcritical survival), oscillation (balanced thresholds), or the irregular fluctuation of edge-of-chaos rules.

On a square grid with B3/S23, a random initial configuration typically produces a burst of activity followed by decline as the population crystallizes into still lifes and oscillators. The growth curve has a characteristic shape: spike, decay, plateau. The plateau is the attractor — stable and periodic structures that survive the initial chaos.

On a hexagonal grid with the same numerical thresholds, the curve shape changes. The birth condition B3 is proportionally more permissive on six neighbors (50%) than on eight (37.5%). The hexagonal B3 universe tends toward higher sustained populations or faster burnout, depending on the survival rule.

The growth network makes these differences visible as diverging curves — same rule numbers, different geometries, different population trajectories.

```gdscript
func population_density(grid: Array[Array], w: int, h: int) -> float:
    var count: int = 0
    for y in h:
        for x in w:
            count += grid[y][x]
    return float(count) / float(w * h)
```

Density is the normalized population — live cells divided by total cells. Density trajectories reveal phase transitions. Below a critical initial density, populations collapse regardless of rule. Above it, self-sustaining structures form. The threshold depends on rule and geometry both. Hexagonal grids shift it because the connectivity differs.

The growth network plots density against generation, mapping the automaton's thermodynamic arc from initial randomness through transient chaos to final equilibrium.

## VR and Embodied Observation

The `hexagon_ca_vr` artifact is the first embodied CA experience in the sequence. Previous maps rendered automata on flat displays — the learner observed from outside, godlike, seeing the entire grid at once. VR places the learner inside the lattice. The hexagonal tiles extend in every direction. The automaton updates around the observer.

This shift in perspective changes what is salient. On a screen, global patterns dominate — gliders, oscillators, density waves. In VR, local dynamics dominate. The learner sees a cluster of cells near their feet flicker through birth and death cycles. They look up and see a distant region behaving differently.

The global pattern exists but is no longer the primary experience. The local rule — the same rule, applied everywhere — becomes palpable through proximity.

The hexagonal geometry in VR has an additional advantage: the tiles pack without gaps or ambiguity. Each tile is visibly surrounded by six others. The neighborhood is not an abstract list of offsets but a physical ring of adjacent cells. When a cell is born, the learner can look at the surrounding six tiles and count the live ones. The totalistic rule becomes verifiable by inspection — three live neighbors, birth occurs, no lookup table required.

Scale reinforces the lesson. On a screen, a 64x64 grid is a thumbnail. In VR, a 64x64 hexagonal lattice is a floor the learner stands on. The tiles are large enough to read. Generations tick past at a pace the learner can follow — fast enough to see patterns form, slow enough to verify individual transitions. The dark sphere anchors the space overhead, a fixed landmark while the lattice evolves underfoot.

## From Compression to Generalization

Totalistic rules compress the rule table by discarding spatial arrangement. This compression is not merely computational convenience. It reveals a principle: many complex behaviors depend on aggregate quantities, not on the specific pattern that produced them. The cell responds to pressure — how many neighbors are alive — rather than to geometry — which ones are alive and where.

This principle echoes across modeling disciplines. Statistical mechanics describes gas behavior through aggregate quantities — temperature, pressure, density — without tracking individual molecules. Neural networks weight summed inputs, not individual synapse identities. Voting systems count ballots without recording who voted for whom. The micro-arrangement is averaged away. The macro-quantity drives the dynamics.

The hexagonal lattice extends the generalization in a different direction — not compressing the rule, but varying the substrate. Same rule logic, different geometry, different behavior.

Together, totalistic compression and lattice variation establish that a cellular automaton is not a grid with a rule. It is a graph with a function. The grid is one graph. The hexagonal lattice is another. Any connected topology supports the same totalistic logic. The specific tessellation is a parameter to be varied, explored, and chosen for purpose.

CA_5 takes the next step: generalizing the state. Cells are no longer binary but carry a gradient of intensities. A cell can decay through intermediate values, cycle through a sequence, brighten and fade. The totalistic sum of multi-valued neighbors produces richer dynamics — waves, excitable media, recovery periods. The counting is the same. The alphabet it operates on expands.

## Possible Artifacts

**totalistic_rule_table** — A side-by-side display contrasting the elementary rule table (8 pattern entries, each a specific left-center-right configuration) with the totalistic rule table (4 sum entries for 1D, or birth/survival threshold lists for 2D). The learner toggles individual entries and watches the automaton evolve under each scheme. The compression becomes visible: multiple elementary patterns that share the same sum collapse into a single totalistic row. Patterns that diverge under elementary rules converge under totalistic ones.

**hex_square_comparator** — Two grids running the same totalistic rule — one square, one hexagonal — from matched initial conditions. Population curves overlay on a shared graph. The learner adjusts birth and survival thresholds and watches how the same numbers produce different dynamics on different geometries. Diagonal artifacts on the square grid contrast with the rounder growth on the hexagonal one. The artifact makes geometry-as-parameter concrete.

**neighborhood_sum_heatmap** — A heatmap overlay on a running automaton where each cell is colored not by its state but by its current neighbor sum. Regions of high sum glow hot; regions of low sum stay cool. Birth and survival thresholds appear as contour lines — cells crossing from below-threshold to above-threshold flip state on the next tick. The learner sees the pressure landscape that drives the automaton's evolution, making the totalistic input visible before the rule produces its output.
