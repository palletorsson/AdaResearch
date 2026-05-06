# Four lines of rules birth a universe on a binary grid where structures live, die, and walk

In CA_1 we saw the substrate — grid, neighborhoods, synchronous update, the double buffer guaranteeing every cell reads the same generation before anyone writes. The rule was generic: a function from neighbor count to next state, placeholder logic. Now a specific rule occupies that slot. Four conditionals. Two constants. The cells stop being abstract bits and start being alive or dead.

The language shifts from computation to biology — birth, survival, death — and the grid becomes a universe.

Conway's Game of Life is not one cellular automaton among many. It is the one that launched a field, proved computational universality on a binary lattice, and demonstrated that four lines of logic produce structures no designer intended. Everything in the CA sequence from here forward references Life as the canonical example.

## B3/S23: Birth and Survival Notation

The Life community compresses totalistic rules into a compact notation. B3/S23 reads: a dead cell with exactly 3 live neighbors is born; a live cell with 2 or 3 live neighbors survives; all other cells die. B lists the neighbor counts that trigger birth. S lists the counts that permit survival. Anything unlisted means death.

```gdscript
const BIRTH: Array[int] = [3]
const SURVIVAL: Array[int] = [2, 3]

func apply_life_rule(cell_state: int, neighbor_count: int) -> int:
    if cell_state == 0:
        # Dead cell — check birth condition
        if neighbor_count in BIRTH:
            return 1
        return 0
    else:
        # Live cell — check survival condition
        if neighbor_count in SURVIVAL:
            return 1
        return 0
```

Four paths through the conditional:

- Dead with exactly 3 neighbors — born
- Dead otherwise — stays dead
- Live with 2 or 3 — survives
- Live with anything else — dies

The biological framing is not decoration. Underpopulation kills through isolation. Overpopulation kills through resource exhaustion. Reproduction requires exactly three parents. Conway searched for a rule that resisted prediction; the biological vocabulary stuck because it maps the dynamics precisely.

The notation scales. B36/S23 is HighLife. B3/S12345678 is Life Without Death. B1357/S1357 is Replicator. Each string specifies a different universe.

B3/S23 is the one that matters because it sits at a critical balance: birth rare enough that infinite growth demands engineering, common enough that random configurations sustain activity.

Plug this into CA_1's double-buffered `step()` function. The infrastructure is inherited wholesale — toroidal wrapping, Moore neighborhood offsets, synchronous read-write separation. Only the rule changes. The entire grid updates in O(width * height) per tick. No differential equations. No iterative solvers. The simplicity of the mechanism is what makes the complexity of the output disorienting.

## Still Lifes: Fixed Points of the Rule

A still life is a pattern whose next generation is identical to itself. Every live cell has 2 or 3 live neighbors — survival satisfied. Every adjacent dead cell has fewer than 3 live neighbors — birth suppressed. The pattern is a fixed point of B3/S23.

The block is the simplest still life — a 2x2 square:

```gdscript
func place_block(grid: Array[Array], x: int, y: int) -> void:
    grid[y][x] = 1;     grid[y][x + 1] = 1
    grid[y + 1][x] = 1; grid[y + 1][x + 1] = 1
```

Every live cell in the block touches exactly 3 others. Survival holds. Every adjacent dead cell touches at most 2. Birth fails. The block persists forever while chaos unfolds around it.

It is inert — an equilibrium point where entropy production halts.

The beehive extends the logic to six cells in a hexagonal bulge:

```gdscript
func place_beehive(grid: Array[Array], x: int, y: int) -> void:
    grid[y][x + 1] = 1;     grid[y][x + 2] = 1
    grid[y + 1][x] = 1;     grid[y + 1][x + 3] = 1
    grid[y + 2][x + 1] = 1; grid[y + 2][x + 2] = 1
```

The loaf, boat, and tub follow the same principle. Each still life is a precise arrangement satisfying the same pair of constraints: internal survival and external suppression.

The `ca_columns` artifact renders columnar still-life structures — vertical stacks of live cells supporting each other indefinitely. Columns demonstrate that stable architecture emerges from the rule without anyone designing it. The form follows from the constraint that every constituent cell must satisfy B3/S23 simultaneously.

Still lifes are attractors in the dynamical system — basins where the state settles and remains. A random soup of cells, left running long enough, decays into a constellation of still lifes and oscillators separated by empty space. The blocks and beehives are the fossils of spent complexity.

## Oscillators: Closed Orbits in State Space

An oscillator returns to its initial configuration after a fixed number of generations — its period. The blinker is the simplest, three cells in a row, period 2:

```gdscript
func place_blinker(grid: Array[Array], x: int, y: int) -> void:
    grid[y][x] = 1
    grid[y][x + 1] = 1
    grid[y][x + 2] = 1
    # Next generation:
    #   Center cell has 2 neighbors — survives
    #   End cells have 1 neighbor each — die
    #   Cells above and below center see 3 neighbors — born
    #   Result: vertical line of three cells
    #   One more generation: horizontal again. Period 2.
```

The center cell has 2 neighbors and survives. The end cells have 1 each and die. Cells directly above and below the center see exactly 3 live neighbors and are born. The horizontal line becomes vertical. One more generation restores the horizontal.

The blinker breathes — expanding along one axis while contracting along the other, maintaining exactly 3 live cells forever.

The toad oscillates with period 2 through a different mechanism. The pulsar has period 3. The pentadecathlon has period 15. Each oscillator traces a closed orbit through Life's state space — a loop the system traverses endlessly.

Oscillators prove that Life is not purely dissipative. Structure transforms without degrading.

The `ca_bridge` artifact renders a bridge configuration incorporating oscillating components that persist while the surrounding grid evolves. The bridge is an island of temporal regularity — periodicity embedded in potential chaos. The coexistence of still lifes (period 1) and oscillators (period > 1) on the same grid is the first hint that Life's state space contains a rich attractor landscape.

## Gliders: Emergent Motion Without Velocity

The glider is five cells that translate diagonally across the grid. Period 4, displacement one cell right and one cell down per cycle:

```gdscript
func place_glider(grid: Array[Array], x: int, y: int) -> void:
    grid[y][x + 1] = 1
    grid[y + 1][x + 2] = 1
    grid[y + 2][x] = 1
    grid[y + 2][x + 1] = 1
    grid[y + 2][x + 2] = 1
```

After four generations the glider reappears one cell right and one cell down — identical shape, shifted position. No cell moves. The pattern moves.

This distinction matters. Life has no concept of velocity or momentum. Movement is an emergent illusion — coordinated birth-and-death cascades that happen to propagate directionally.

The glider travels at c/4, where c is Life's speed of light: one cell per generation, the maximum rate at which information propagates through neighbor interactions. The lightweight spaceship (LWSS) moves at c/2. Nothing exceeds c. The Moore neighborhood constrains propagation to one cell per tick, establishing an absolute speed limit for the lattice.

On the toroidal grid a glider orbits forever. It exits one edge, enters the opposite. A five-cell packet traversing the lattice in a predictable loop.

Persistent directed motion from a rule that encodes no concept of direction.

The `mirrored_cellular_automata` artifact runs two Life grids in bilateral symmetry. Gliders from symmetric seeds travel in mirror-image trajectories, demonstrating that the rule preserves whatever symmetry the initial conditions contain. Symmetric inputs under a symmetric rule yield symmetric outputs — the formal property distinguishing a butterfly from a cloud.

The mirroring bridges back to CA_1's `persian_rug`, where four-fold symmetry was preserved through totalistic counting. Here the same preservation principle produces traveling structures instead of static ornament.

## The Gosper Glider Gun: Finite Pattern, Infinite Growth

Conway conjectured that no finite Life pattern grows without limit. Bill Gosper refuted this with the glider gun — a period-30 oscillator that emits a new glider every 30 generations:

```gdscript
func place_gosper_gun(grid: Array[Array], x: int, y: int) -> void:
    # Left block
    grid[y + 4][x] = 1;     grid[y + 4][x + 1] = 1
    grid[y + 5][x] = 1;     grid[y + 5][x + 1] = 1
    # Left cluster
    grid[y + 2][x + 12] = 1; grid[y + 2][x + 13] = 1
    grid[y + 3][x + 11] = 1; grid[y + 3][x + 15] = 1
    grid[y + 4][x + 10] = 1; grid[y + 4][x + 16] = 1
    grid[y + 5][x + 10] = 1; grid[y + 5][x + 14] = 1
    grid[y + 5][x + 16] = 1; grid[y + 5][x + 17] = 1
    grid[y + 6][x + 10] = 1; grid[y + 6][x + 16] = 1
    grid[y + 7][x + 11] = 1; grid[y + 7][x + 15] = 1
    grid[y + 8][x + 12] = 1; grid[y + 8][x + 13] = 1
    # Right cluster
    grid[y + 0][x + 24] = 1; grid[y + 0][x + 25] = 1
    grid[y + 1][x + 22] = 1; grid[y + 1][x + 25] = 1
    grid[y + 2][x + 20] = 1; grid[y + 2][x + 21] = 1
    grid[y + 3][x + 20] = 1; grid[y + 3][x + 21] = 1
    grid[y + 4][x + 20] = 1; grid[y + 4][x + 21] = 1
    grid[y + 5][x + 22] = 1; grid[y + 5][x + 25] = 1
    grid[y + 6][x + 24] = 1; grid[y + 6][x + 25] = 1
    # Right block
    grid[y + 2][x + 34] = 1; grid[y + 2][x + 35] = 1
    grid[y + 3][x + 34] = 1; grid[y + 3][x + 35] = 1
```

Thirty-six cells. Two stable blocks anchor the extremes. Two oscillating clusters interact through a narrow channel, ejecting a glider every 30 ticks. The gun is periodic — it returns to its initial state — but gliders accumulate.

After 300 ticks: 10 gliders. After 3000: 100. Live cell count grows without bound. Conway's conjecture was false.

The gun matters because gliders serve as signals. Presence or absence of a glider at a specific time and place encodes one bit. Guns produce clock-synchronized bit streams. Collisions between glider streams perform logic:

```gdscript
# Conceptual: two glider streams converge at a collision point
# Both arrive simultaneously — annihilation, output 0 (AND gate inverted)
# Only one arrives — passes through, output 1
# Reflectors redirect surviving gliders — wiring

var gun_a_position := Vector2i(0, 0)
var gun_b_position := Vector2i(40, 40)
var collision_point := Vector2i(20, 20)
# Distance determines arrival timing. Gun period determines bit rate.
```

Arrange enough guns and collision geometries and B3/S23 becomes a programmable computer. The same rule that produces blinkers supports arbitrary computation given sufficient grid and runtime.

Complexity does not require complex rules. It requires the right simple rules at sufficient scale.

## Six Phenomena From One Rule

Six dynamics — avalanche, dendrite, disease, ecosystem, percolation, crack — all arise from B3/S23 under different initial conditions. The rule is fixed. Only the starting configuration changes. The diversity of outcome from unity of mechanism is the central demonstration.

**Avalanche** begins with a dense field perturbed by a single cell flip. Cascading births and deaths propagate outward — each new state change creates neighbor conditions that trigger further changes. One bit of perturbation amplifies into global reorganization. Deterministic chaos: no randomness in the rule, exponential sensitivity in the dynamics.

**Dendrite** growth starts from a compact seed in empty space. The birth rule activates at the cluster boundary where dead cells touch exactly three live ones. Branches extend, each tip a zone of active birth. The branching structure emerges from the geometry of which dead cells meet the birth threshold — not programmed, not designed, purely consequent.

**Disease** models epidemic spread as an isomorphism. Seed a dead grid with a small live cluster. The birth rule propagates outward — each generation creates conditions for the next ring of births while the interior overcrowds and dies. Susceptible (dead), infected (born), recovered (dead from overpopulation). Life does not simulate disease. Life and disease share the same structure — local threshold activation on a graph.

**Ecosystem** dynamics appear at intermediate densities. Dense clusters consume sparse neighbors through overpopulation death, then die themselves, leaving space for regrowth. Population oscillates at the macro scale though no cell remembers its history. The memoryless rule produces memory-like behavior through spatial patterning.

**Percolation** reveals a phase transition. Below a critical density the population goes extinct — too few cells to sustain birth chains. Above it, spanning clusters persist indefinitely. The transition is sharp: a small density change produces a qualitative shift from death to survival.

This is a computational analog of physical percolation — the moment a random lattice becomes connected.

**Crack** propagation runs opposite to dendrite growth. A fracture line of death advances through a live field, splitting it into isolated regions. The crack follows where survival conditions fail — cells with too many or too few neighbors, a wave of local rule violations propagating through a stable medium.

All six emerge from four conditionals. The rule contains no concept of avalanche, disease, or ecosystem. These are names for patterns in the dynamics — descriptions of how identical local logic produces qualitatively different global behavior depending on initial structure.

## Garden of Eden and the Arrow of Time

Not every grid configuration arises from running Life forward. A Garden of Eden pattern has no predecessor — no generation that would produce it under B3/S23. Placeable by hand but never emergent from the rule's own dynamics.

```gdscript
func has_predecessor(pattern: Array[Array], w: int, h: int) -> bool:
    # The predecessor search space is 2^((w+2)*(h+2)) candidates.
    # Each candidate must produce the given pattern when Life steps once.
    # Exhaustive search is infeasible beyond small patches.
    # Existence proven by Edward Moore (1962) via pigeonhole argument.
    # Detection in practice requires SAT solvers or constraint propagation.
    return false  # Placeholder — no tractable general algorithm
```

The Life rule is not injective — multiple configurations map to the same successor. If the mapping is many-to-one, some states have no preimage. These orphans are Gardens of Eden.

Their existence means Life is irreversible. Forward is deterministic. Backward is ambiguous or impossible. Time in Life has a direction encoded in the rule itself, not imposed externally.

This irreversibility connects to the entropy arc running through the CA sequence. Each generation can destroy information — two different starting states evolving to the same successor means one bit of distinction is lost. The arrow of time in Life is an arrow of information loss, the same arrow thermodynamics describes in continuous systems.

The QFEP framework surfaces here. The E term tracks irreversible compression of state space — the many-to-one collapse that creates Gardens of Eden. The phi term captures the structural complexity that persists despite compression: gliders, oscillators, still lifes, organized patterns surviving amid information loss.

Life sustains high phi (rich structure) alongside nonzero E (ongoing information transformation). The balance between creation and destruction of pattern is what makes B3/S23 interesting rather than trivial. The Q term — the qualitative character of the system — separates Life from the thousands of B/S variants that produce only death or noise.

## The Edge of Chaos

Most B/S rules are dull. Some kill everything regardless of initial conditions — the grid goes dark. Others fill every cell — the grid saturates. B3/S23 is neither.

Birth is rare enough that unbounded growth requires precise engineering (the glider gun). Survival is permissive enough for stable structures but restrictive enough that they demand exact cell placement. Random soups sustain activity for hundreds of generations before settling into still lifes, oscillators, and empty space.

This places Life at the edge of chaos — a region in rule space where ordered behavior (still lifes, oscillators) and disordered behavior (random debris) coexist on the same grid under the same rule at the same moment.

The `ca_bridge` artifact embodies this coexistence. A stable bridge structure persists while surrounding cells churn through transient configurations. Perturb one cell of the bridge and it may collapse into mobile debris. Stability is real but exact — fragile under perturbation, yet indefinitely persistent without it.

Christopher Langton's lambda parameter quantifies position in rule space. Low lambda (few birth conditions) produces dead grids. High lambda (many birth conditions) produces saturated noise. Rules near the critical lambda — B3/S23 among them — produce the complex dynamics where computation, structure, and unpredictability intersect.

CA_3 systematizes this observation by dropping to one dimension and surveying all 256 elementary rules, classifying them into Wolfram's four classes. Life's edge-of-chaos position is not an accident. It is the property that enables gliders, guns, still lifes, and chaos to coexist within a single rule.

The same balance that makes Life computationally universal makes it scientifically generative — one system producing enough variety to anchor an entire field.

## Possible Artifacts

**glider_gun** — A running Gosper glider gun on a visible grid with generation counter and live-cell count. The learner watches internal oscillation and sees emitted gliders as byproducts of periodic dynamics. The growing cell count makes unbounded growth tangible, connecting to the Turing completeness argument where glider streams encode information.

**pattern_library** — An interactive catalog of canonical structures: still lifes (block, beehive, loaf, boat), oscillators (blinker, toad, pulsar, pentadecathlon), spaceships (glider, LWSS, MWSS). Each placeable on a shared grid. The learner assembles configurations and observes interactions — two colliding gliders produce a block, an oscillator, or annihilation depending on phase and angle.

**sensitivity_probe** — Two identical grids side by side. Flip one cell on one grid. Run both forward. A difference overlay highlights diverging cells generation by generation. Deterministic chaos visible as one bit amplifies into global divergence. Connects the avalanche phenomenon to formal sensitivity analysis.

**density_scanner** — A percolation experiment. The learner sets initial density with a slider, seeds the grid, watches evolution. Below the critical threshold the population dies. Above it, stable structures persist. A real-time population graph reveals the phase transition — the sharp boundary between extinction and survival.
