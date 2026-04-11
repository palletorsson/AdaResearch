# Four lines of rules produce a universe where structures are born, persist, and die on a binary grid

CA_1 established the substrate — grid, neighborhood, synchronous update. Now one specific rule set transforms that substrate into a universe. The grid is the same. The double buffer is the same. The Moore neighborhood is the same. What changes is the rule — and with it, everything.

Four conditionals replace the generic `apply_rule` function. The cells stop being abstract states and start being alive or dead. The language shifts from computation to biology. Birth. Survival. Death. The most studied cellular automaton in history runs on a rule that fits in one sentence.

## B3/S23: The Notation

The Life community encodes totalistic rules in birth/survival notation. B3/S23 means: a dead cell with exactly 3 live neighbors is born; a live cell with 2 or 3 live neighbors survives; everything else dies.

The B lists neighbor counts that trigger birth. The S lists counts that permit survival. Any unlisted condition results in death.

The notation is compact enough to fit in a subject line, expressive enough to distinguish thousands of rule variants. B36/S23 is HighLife. B3/S12345678 is Life Without Death. B1357/S1357 is Replicator. Each produces a different universe. But B3/S23 — Conway's Game of Life — is the one that launched a field.

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

Four paths:

- Dead with 3 neighbors — born
- Dead otherwise — stays dead
- Live with 2 or 3 — survives
- Live otherwise — dies

The biological metaphor is precise: underpopulation kills through isolation, overpopulation kills through resource exhaustion, reproduction requires exactly 3 parents. Conway was searching for a rule that resisted prediction — the biological language stuck because it maps so cleanly.

Plugging this into CA_1's double-buffered `step()` produces the complete simulation. The infrastructure is inherited wholesale — toroidal wrapping, synchronous read-write separation, Moore neighborhood offsets. Only the four-line rule is new.

The entire universe updates in O(width * height) per tick. No differential equations. No iterative solvers. The simplicity of the update is what makes the complexity of the output disorienting.

## Still Lifes: Structures That Refuse to Change

A still life is a pattern whose next generation is identical to its current one. Every live cell has exactly 2 or 3 live neighbors — survival. Every adjacent dead cell has fewer than 3 live neighbors — no birth. The pattern is a fixed point of the Life rule.

The simplest still life is the block — a 2x2 square:

```gdscript
# Block: each live cell has exactly 3 live neighbors
func place_block(grid: Array[Array], x: int, y: int) -> void:
    grid[y][x] = 1;     grid[y][x + 1] = 1
    grid[y + 1][x] = 1; grid[y + 1][x + 1] = 1
```

Every cell in the block touches exactly 3 others — survival satisfied. Every adjacent dead cell touches at most 2 — birth not met. The block is inert. It persists forever while chaos unfolds around it.

The beehive is the next simplest — six cells in a hexagonal bulge:

```gdscript
# Beehive: six cells, each with 2 or 3 live neighbors
func place_beehive(grid: Array[Array], x: int, y: int) -> void:
    grid[y][x + 1] = 1;     grid[y][x + 2] = 1
    grid[y + 1][x] = 1;     grid[y + 1][x + 3] = 1
    grid[y + 2][x + 1] = 1; grid[y + 2][x + 2] = 1
```

The loaf, the boat, the tub — dozens of still lifes exist. Each is a precise arrangement where every live cell satisfies survival and every adjacent empty cell falls below the birth threshold.

Still lifes are equilibrium points — attractors where entropy production halts. The `ca_columns` artifact in this map renders stable columnar structures that embody this principle: vertical arrangements of live cells supporting each other's survival indefinitely.

## Oscillators: Structures That Breathe

An oscillator returns to its initial state after a fixed number of generations — its period. The simplest is the blinker, three cells in a row:

```gdscript
# Blinker: period-2 oscillator
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

The blinker alternates between horizontal and vertical every tick. The mechanism is transparent: the center cell always survives, the end cells always die, the perpendicular neighbors always satisfy the birth condition. The pattern breathes — expanding along one axis while contracting along the other.

The toad is another period-2 oscillator — two offset rows of three cells that slide back and forth. The pulsar has period 3. The pentadecathlon has period 15. Each period represents a closed orbit in Life's state space.

Oscillators demonstrate that Life's dynamics are not purely dissipative. The blinker maintains exactly 3 live cells forever. The pulsar fluctuates between 48 and 56. Structure is conserved even as it transforms — persistent but dynamic, stable but never static. The bridge between still lifes and chaos.

## Gliders: Structures That Walk

The glider is the smallest pattern that translates across the grid. Five cells, period 4, displacement of one cell diagonally every four generations:

```gdscript
# Glider: moves one cell diagonally every 4 ticks
func place_glider(grid: Array[Array], x: int, y: int) -> void:
    grid[y][x + 1] = 1
    grid[y + 1][x + 2] = 1
    grid[y + 2][x] = 1
    grid[y + 2][x + 1] = 1
    grid[y + 2][x + 2] = 1
```

After four generations, the glider reappears one cell right and one cell down — identical in shape, displaced in space. No cell moves. The pattern moves.

The distinction matters: Life has no concept of velocity or momentum. Movement is an emergent illusion — local birth-and-death cycles that happen to propagate directionally.

The glider travels at c/4 — one quarter of Life's speed of light. The speed of light is one cell per generation, the maximum rate of information propagation through neighbor interactions. Faster spaceships exist — the lightweight spaceship (LWSS) moves at c/2 — but nothing exceeds c.

On the toroidal grid, a glider walks forever. It exits one edge, enters the opposite. A five-cell packet of information traversing the grid in a predictable orbit. Persistent directed motion from a rule that encodes no concept of direction.

## The Gosper Glider Gun: Unbounded Growth

Conway conjectured that no finite Life pattern could grow without limit. Bill Gosper disproved it with the glider gun — a period-30 oscillator that emits a new glider every 30 generations.

```gdscript
# Gosper glider gun: 36 cells, period 30
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

Thirty-six cells. Two stable blocks anchor the ends. Two oscillating clusters interact through a narrow channel, ejecting a five-cell glider every 30 ticks. The gun is periodic — it returns to its initial state — but the gliders accumulate.

After 30 ticks: 1 glider. After 300: 10. After 3000: 100. Live cell count grows without bound. Conway's conjecture was false. Finite patterns can produce infinite growth.

The glider gun connects directly to Turing completeness. Gliders serve as signals — bits flying across the grid. Guns produce streams of those signals. Collisions between gliders perform logic: AND, OR, NOT. Arrange enough guns and collision sites and the result is a programmable computer built entirely from B3/S23.

## Sensitivity to Initial Conditions

Place a block on an empty grid. Wait a thousand generations. Unchanged.

Add a single live cell adjacent to the block — and the pattern may cascade into hundreds of active cells, producing gliders, oscillators, debris fields that take thousands of generations to settle. One bit of difference. Arbitrarily large divergence. Deterministic chaos — the rule contains no randomness, but the system is exponentially sensitive to perturbation.

The `ca_bridge` artifact demonstrates this. It renders a stable bridge structure — still lifes and oscillators spanning a grid region. Perturb one cell and the bridge collapses into mobile debris. Stability is real but fragile — exact placement of every constituent cell is required. Robustness and fragility coexist at different scales.

The six phenomena in this map are all expressions of sensitivity under different initial conditions:

- **Avalanche** — cascading births and deaths from small perturbation in a dense field
- **Dendrite** — branching growth from a seed into empty space, each branch tip a zone of active birth
- **Disease** — epidemic spread where live cells "infect" dead neighbors through the birth rule, the wavefront propagating outward in SIR dynamics on a lattice
- **Ecosystem** — dense clusters consuming sparse ones through overpopulation death, then dying themselves, leaving space for regrowth
- **Percolation** — below a critical initial density the population dies; above it, spanning clusters survive indefinitely
- **Crack** — a fracture line of death propagating through a live field, splitting it into isolated regions

All six. One rule. B3/S23. The only variable is initial configuration. The diversity of outcome from unity of mechanism — this is what makes Life the canonical cellular automaton.

## Garden of Eden: States Without Predecessors

Not every grid configuration can be reached by running Life forward. A Garden of Eden pattern has no predecessor — no previous generation that would produce it under B3/S23. It can be placed by hand but can never arise from the automaton's own dynamics.

```gdscript
func is_garden_of_eden(pattern: Array[Array], w: int, h: int) -> bool:
    # Predecessor space: 2^((w+2)*(h+2)) candidates.
    # The pattern plus a one-cell border that affects the interior.
    # Exhaustive search is infeasible beyond small patches.
    # Existence proven mathematically; detection requires SAT solvers.
    return false  # Placeholder — no tractable algorithm exists
```

Edward Moore proved their existence in 1962. The argument: the Life rule is not injective — multiple configurations can map to the same next state — so the generation function compresses state space. If the mapping is many-to-one, some states must be unreachable. These orphan configurations are Gardens of Eden.

The implication is irreversibility. Running forward is trivial — apply the rule. Running backward is ambiguous — multiple predecessors may exist, or none at all.

Time in Life has a direction. The arrow of time is built into the rule, not imposed from outside.

## Turing Completeness: The Grid as Computer

Life is Turing complete. Any computation a universal Turing machine performs, Life can perform given sufficient grid and runtime. The proof is constructive.

Two gliders approaching from precise angles annihilate — an AND gate where output exists only if both inputs arrive. A glider stream meeting a still-life reflector redirects — wiring. A gun provides the clock signal. Presence or absence of a glider at a specific time and place encodes one bit.

```gdscript
# Conceptual: a Life-based XOR gate
# Two glider streams converge at a collision point.
# Both arrive simultaneously — annihilation, output 0.
# Only one arrives — passes through, output 1.

var gun_a_position := Vector2i(0, 0)
var gun_b_position := Vector2i(40, 40)
var collision_point := Vector2i(20, 20)

# Distance determines arrival time.
# Gun period determines bit rate.
```

Working Life computers exist — patterns millions of cells wide that execute programs. The same B3/S23 that produces blinkers also supports arbitrary computation. The gap between a 2x2 block and a working CPU is not mechanism — the rule is identical — but scale and arrangement.

Complexity does not require complex rules. It requires the right simple rules at sufficient scale.

## The Biological Vocabulary

Conway chose "birth," "survival," and "death" deliberately — not metaphors applied after the fact but the design vocabulary itself. B3/S23 encodes a lifecycle: cells born when supported by 3 neighbors, surviving when local density falls in a narrow band, dying when isolated or overcrowded.

This is not a simulation of biology but an abstraction that captures the formal structure of population dynamics. The abstraction is precise enough that real models of epidemic spread, forest fire propagation, and predator-prey cycles all reduce to neighbor-counting rules on grids.

The `mirrored_cellular_automata` artifact runs two Life grids in bilateral symmetry — whatever evolves on the left is reflected on the right. The result looks biological not because it simulates any organism but because bilateral symmetry is a structural principle shared between Life patterns and living bodies. Symmetric initial conditions under a symmetric rule produce symmetric evolution — the formal property that distinguishes a butterfly from a cloud.

The disease phenomenon makes the isomorphism explicit. Seed a dead grid with a small cluster of live cells. The birth rule propagates outward — each generation creates conditions for the next ring of births. This is SIR dynamics on a lattice: susceptible (dead), infected (newly born), recovered (dead again from overcrowding). Life does not model disease. Life and disease models share the same mathematical structure — local threshold rules on graphs.

## The Edge of Chaos

Life sits at a critical point in rule space. Most B/S rules are boring — they kill everything or fill the grid. B3/S23 is balanced: birth rare enough that unbounded growth requires precise engineering, common enough that random soups sustain activity. Survival permissive enough for stable structures, restrictive enough that they demand exact arrangement.

This balance places Life at the edge of chaos — a quantifiable region where order (still lifes, oscillators) and disorder (random debris) coexist. The interesting structures live at the boundary. The rule neither maximizes nor minimizes entropy. It sustains a regime where computational capacity is maximized.

The `ca_bridge` and `ca_columns` artifacts anchor this. The bridge is an ordered island in a sea of potential chaos. The columns demonstrate periodicity. Both are attractors: perturb slightly and the system either returns to the structure or collapses into debris.

The coexistence of stability and fragility on the same grid, under the same rule, at the same moment — that is the signal the entropy arc follows from here through CA_3's systematic classification and beyond.

## Possible Artifacts

**glider_gun** — A running Gosper glider gun on a visible grid. Period-30 oscillation emitting one glider per cycle. Generation counter and live-cell counter show linear growth in real-time. The learner watches internal oscillation and sees emitted gliders as byproducts of a periodic process — structured waste carrying energy away from the source.

**pattern_library** — An interactive catalog: still lifes (block, beehive, loaf, boat), oscillators (blinker, toad, pulsar, pentadecathlon), spaceships (glider, LWSS, MWSS). Each placeable on a shared grid. The learner assembles configurations and observes interactions — two colliding gliders produce a block, an oscillator, or annihilation depending on phase and angle.

**sensitivity_probe** — Two identical grids side by side. Flip one cell on one grid. Let both evolve. A difference overlay highlights diverging cells generation by generation. Deterministic chaos made visible — one bit amplified into global divergence.

**density_scanner** — A percolation experiment. Set initial density, watch the grid evolve. Below the critical threshold the population dies. Above it, stable structures persist. A population graph reveals the phase transition between extinction and survival.
