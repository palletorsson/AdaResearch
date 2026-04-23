# A grid of cells where each reads its neighbors and rewrites itself — local rules, global pattern

Everything until now has been continuous. Vectors slide through real-valued space. Forces accumulate as smooth curves. Sine waves oscillate without gaps. The mathematics assumed infinitely divisible quantities — position could be 3.7 or 3.71 or 3.714159, and the simulation didn't care. Cellular automata abandon that assumption entirely.

Space is a grid. Time advances in ticks. Each cell holds one of a finite set of states. No gradients, no interpolation, no smooth transitions. Discrete space, discrete time, discrete state. The simplest possible substrate for computation — and from it, complexity that rivals anything the continuous world produced.

A cellular automaton is a grid of cells. Each cell has a state. Each cell has neighbors. Each cell applies a rule — the same rule, everywhere, simultaneously — that reads the current neighbor states and produces the next state. One generation becomes the next. The automaton steps forward. That is the entire mechanism.

## The Grid

The substrate is a 2D array. Each cell holds an integer — 0 or 1 for the simplest case. Dead or alive. Off or on. The grid has width, height, and nothing else.

```gdscript
var width: int = 64
var height: int = 64
var grid: Array[Array] = []

func _ready() -> void:
    grid.resize(height)
    for y in height:
        grid[y] = []
        grid[y].resize(width)
        for x in width:
            grid[y][x] = 0
```

A flat allocation. Every cell starts at zero — a dead field. The grid is indexed `[y][x]` because rows come first, columns second. This matches how screens draw: top to bottom, left to right. It also matches how matrices are stored. The convention matters when reading neighbor offsets.

The grid is the entire world. There is no coordinate system beyond integer indices. No floating-point position, no subpixel precision. Cell `(12, 7)` exists. Cell `(12.5, 7.3)` does not.

This discreteness is not a limitation — it is the point. Continuous systems approximate. Cellular automata enumerate. Every possible state of a 64×64 binary grid is one of 2^4096 configurations. Astronomical, but finite. The automaton walks through that space one tick at a time.

## The Neighborhood

Each cell needs to know its surroundings. Two conventions dominate. The von Neumann neighborhood includes four cells — up, down, left, right. The Moore neighborhood includes eight — the four cardinal directions plus the four diagonals.

```gdscript
# Von Neumann neighborhood: 4 adjacent cells
const VON_NEUMANN: Array[Vector2i] = [
    Vector2i(0, -1),   # up
    Vector2i(0, 1),    # down
    Vector2i(-1, 0),   # left
    Vector2i(1, 0),    # right
]

# Moore neighborhood: 8 surrounding cells
const MOORE: Array[Vector2i] = [
    Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
    Vector2i(-1,  0),                  Vector2i(1,  0),
    Vector2i(-1,  1), Vector2i(0,  1), Vector2i(1,  1),
]
```

Offsets from the center cell. Add any offset to a cell's position to reach one neighbor. The von Neumann neighborhood forms a plus sign. The Moore neighborhood forms a square — the complete 3×3 block minus the center. The choice of neighborhood determines the automaton's character. Von Neumann rules tend to produce diamond-shaped growth. Moore rules produce squares and diagonals. The neighborhood is the automaton's sensory apparatus — it defines what information each cell can access.

Edges require a decision. A cell at position `(0, 0)` has no neighbor to the left or above. Two options: treat out-of-bounds cells as permanently dead (boundary condition), or wrap the grid into a torus so the left edge connects to the right and the top connects to the bottom.

```gdscript
func get_cell(x: int, y: int) -> int:
    # Toroidal wrapping — edges connect to opposite edges
    var wx: int = posmod(x, width)
    var wy: int = posmod(y, height)
    return grid[wy][wx]

func count_neighbors(x: int, y: int, neighborhood: Array[Vector2i]) -> int:
    var count: int = 0
    for offset in neighborhood:
        count += get_cell(x + offset.x, y + offset.y)
    return count
```

`posmod` handles the wrapping — negative indices loop to the far side. The grid becomes borderless. A glider that exits the right edge reappears on the left. This is the topological choice: a flat grid with dead borders versus a torus with no borders at all. The torus is cleaner for studying pattern dynamics because nothing leaks out.

## The Rule

A rule is a function from neighborhood configuration to next state. For a binary grid with Moore neighborhood, each cell sees 8 neighbors, each either 0 or 1. That is 2^8 = 256 possible configurations — plus the cell's own state, making 512. A complete rule table maps every one of these 512 inputs to an output: 0 or 1.

Most interesting automata compress this. Instead of a 512-entry lookup table, they summarize the neighborhood as a count. "How many of my 8 neighbors are alive?" The answer ranges from 0 to 8. The rule then becomes a compact function of two variables: the cell's current state and its neighbor count.

```gdscript
func apply_rule(cell_state: int, neighbor_count: int) -> int:
    # A simple threshold rule: alive if exactly 3 neighbors,
    # or if already alive and 2 neighbors
    if neighbor_count == 3:
        return 1
    if cell_state == 1 and neighbor_count == 2:
        return 1
    return 0
```

This particular rule has a name — it is Conway's Game of Life, the subject of the next map. Here the point is structural: the rule is small. A handful of conditionals. No memory of previous generations, no awareness of position on the grid, no special cases. The same function applied to every cell at every tick. The rule is local, uniform, and memoryless. Everything else — pattern, structure, complexity — emerges from iteration.

## Synchronous Update: The Double Buffer

The critical constraint: all cells must read from the same generation before any cell writes its next state. If cell `(5, 3)` updates first and its new state leaks into the read of cell `(5, 4)`, the automaton breaks. Neighbor reads would mix current and next states. The result would depend on update order — and the whole point of a cellular automaton is that update order does not matter.

The solution is a double buffer. Two grids. One holds the current generation (read-only). The other receives the next generation (write-only). After every cell has been computed, swap the buffers.

```gdscript
var grid_current: Array[Array] = []
var grid_next: Array[Array] = []

func step() -> void:
    for y in height:
        for x in width:
            var neighbors: int = count_neighbors_from(grid_current, x, y)
            var state: int = grid_current[y][x]
            grid_next[y][x] = apply_rule(state, neighbors)

    # Swap buffers — next becomes current
    var temp := grid_current
    grid_current = grid_next
    grid_next = temp

func count_neighbors_from(source: Array[Array], x: int, y: int) -> int:
    var count: int = 0
    for offset in MOORE:
        var nx: int = posmod(x + offset.x, width)
        var ny: int = posmod(y + offset.y, height)
        count += source[ny][nx]
    return count
```

Read from `grid_current`. Write to `grid_next`. Swap. The separation guarantees that every cell sees a consistent snapshot of the current generation. No cell reads stale data. No cell reads future data. The update is synchronous — as if every cell computed its next state at the same instant.

This is the fundamental difference between a cellular automaton and a serial algorithm. In a serial program, order matters. Updating cell A before cell B means B sees A's new state. In a cellular automaton, order is irrelevant. The double buffer enforces this. Parallelism is not an optimization — it is a semantic requirement.

## Elementary Cellular Automata: One Dimension

Before the 2D grid, consider the simplest possible case. A 1D row of cells. Each cell has two states (0 or 1). Each cell looks at itself and its two immediate neighbors — three cells total. Three binary cells produce 2^3 = 8 possible configurations. A rule must assign an output (0 or 1) to each of these 8 configurations. That is 2^8 = 256 possible rules.

Stephen Wolfram numbered them. Each rule is an 8-bit number. Rule 30. Rule 110. Rule 90. The number itself encodes the lookup table.

```gdscript
func wolfram_rule(rule_number: int, left: int, center: int, right: int) -> int:
    # The three-cell neighborhood forms a 3-bit index
    var index: int = (left << 2) | (center << 1) | right
    # The rule number's bits encode the output for each index
    return (rule_number >> index) & 1
```

Three cells. Three bits. An index from 0 to 7. The rule number's bit at that index is the output. Rule 30 in binary is `00011110`.

Index 0 (neighborhood `000`) maps to 0. Index 1 (`001`) maps to 1. Index 2 (`010`) maps to 1. Index 3 (`011`) maps to 1. Index 4 (`100`) maps to 1. The rest map to 0.

```gdscript
func step_1d(cells: Array[int], rule_number: int) -> Array[int]:
    var next: Array[int] = []
    next.resize(cells.size())
    for i in cells.size():
        var left: int = cells[posmod(i - 1, cells.size())]
        var center: int = cells[i]
        var right: int = cells[posmod(i + 1, cells.size())]
        next[i] = wolfram_rule(rule_number, left, center, right)
    return next
```

Start with a single 1 in a row of zeros. Apply Rule 30. Generation after generation, the pattern cascades downward — asymmetric, aperiodic, chaotic. From one bit and one rule, a structure that passes statistical tests for randomness. Rule 110 is even stranger — it has been proven Turing complete. A one-dimensional binary automaton with a three-cell neighborhood can compute anything a general-purpose computer can. The simplest possible computational substrate, and it is universal.

The rule-as-number encoding is the key insight. The rule is not a program. It is data — an integer whose binary digits define behavior. Change the integer, change the universe. This is what makes cellular automata a natural laboratory: the space of all possible rules is small enough to enumerate, large enough to contain chaos, universality, and everything between.

## The Persian Rug

The `persian_rug` artifact demonstrates a principle: symmetric initial conditions plus symmetric rules produce symmetric patterns. Start with a grid that has mirror symmetry — identical left-to-right, or four-fold symmetric about the center.

```gdscript
func initialize_symmetric(grid: Array[Array], w: int, h: int) -> void:
    # Set random states in the top-left quadrant
    for y in h / 2:
        for x in w / 2:
            var state: int = randi() % 2
            grid[y][x] = state
            grid[y][w - 1 - x] = state          # mirror horizontal
            grid[h - 1 - y][x] = state          # mirror vertical
            grid[h - 1 - y][w - 1 - x] = state  # mirror both
```

Four quadrants. One random, three reflected. The initial grid has four-fold symmetry. Now apply a rule that depends only on neighbor count — not on direction. The Moore neighborhood is symmetric: it treats all eight neighbors equally. The count does not distinguish left from right, up from down. So the rule output inherits the input symmetry.

Generation after generation, the symmetry propagates. The pattern evolves, grows in complexity, but the mirror axes never break. Randomness fills in the details — no two runs produce the same pattern — but the structure remains balanced. The result resembles a persian rug: ornate, finely detailed, unmistakably symmetric. The automaton does not know about symmetry. It knows about neighbor counts. Symmetry is emergent — a consequence of symmetric inputs processed by symmetric rules.

This is the automaton as pattern amplifier. Feed it structure, and it elaborates. Feed it disorder, and it complexifies. The rule does not create the symmetry or the chaos. It propagates whatever the initial conditions contain.

## The Connectivity Graph

The `line_network_ca` artifact strips the automaton to its topology. Instead of rendering cells as colored squares, it draws the neighbor relationships as edges in a graph. Each cell becomes a node. Each neighbor pair becomes a line connecting two nodes.

```gdscript
func build_neighbor_graph(w: int, h: int, neighborhood: Array[Vector2i]) -> Array[Array]:
    var edges: Array[Array] = []
    for y in h:
        for x in w:
            var node_id: int = y * w + x
            for offset in neighborhood:
                var nx: int = posmod(x + offset.x, w)
                var ny: int = posmod(y + offset.y, h)
                var neighbor_id: int = ny * w + nx
                if neighbor_id > node_id:  # avoid duplicate edges
                    edges.append([node_id, neighbor_id])
    return edges
```

The grid vanishes. What remains is a graph — nodes connected by edges. Von Neumann neighborhoods produce a lattice graph with degree 4. Moore neighborhoods produce degree 8. Wrap the edges and you see the torus topology explicitly: edge nodes connect across the boundary.

This representation reveals something the grid hides. The cellular automaton does not require a grid. It requires a graph. Any set of nodes with defined neighbor relationships can support a rule. Hexagonal grids, triangular grids, irregular networks, random graphs — all valid substrates. The 2D rectangular grid is the simplest, the most intuitive, the most visualizable. But it is a choice, not a constraint.

The graph also makes information flow visible. A signal at cell `(0, 0)` reaches cell `(3, 3)` in three steps through the Moore graph — three diagonal hops. Through the von Neumann graph, it takes six steps — three right, three down. The neighborhood determines the speed of information propagation, which determines how fast patterns can grow, which determines the character of the automaton's dynamics. Topology shapes behavior.

## Emergence

A 2D binary cellular automaton with Moore neighborhood has one parameter: the rule. The rule is a function from 10 inputs (1 cell state + 9 possible neighbor counts, though only 0–8 occur) to 1 binary output. The entire specification fits in a few lines of code. No designer chose the global patterns. No algorithm optimizes for structure. The rule says: given this local situation, produce this next state. Period.

Yet from Rule 30 — a single integer — comes structure that resists compression. From symmetric initial conditions and counting rules come persian rugs. From the Game of Life rules come gliders, oscillators, logic gates, and universal computation. The outputs are wildly disproportionate to the inputs. This disproportion is the defining fact of cellular automata and the central concern of the entropy arc.

Entropy in this context is not thermodynamic. It is informational. The initial state has a certain amount of structure — its entropy can be measured by how compressible it is. The rule transforms that entropy. Some rules increase disorder: simple patterns dissolve into noise. Some rules decrease it: random soups crystallize into repeating structures. Some rules — the interesting ones — sit at the boundary, producing neither order nor chaos but persistent, evolving complexity.

The previous sequences — vectors, forces, waves — described systems where global behavior follows from global equations. F = ma is a law that applies to every particle, but each particle carries its own position, its own velocity. Cellular automata invert this. There is no global equation.

There are only cells, each executing the same local rule, each ignorant of the global state. The global pattern is a side effect. No one is in charge. No one designed the output. The automaton simply runs, and structure appears.

## Possible Artifacts

**step_by_step_visualizer** — A slow-motion single-step tool that pauses the automaton and lets the learner advance one cell at a time. For each cell, it highlights the neighborhood, displays the neighbor count, shows the rule lookup, and reveals the next state before committing it. The double-buffer logic becomes visible: the current grid stays frozen while next-state values accumulate in an overlay. Stepping through a full generation — cell by cell — builds intuition for why synchronous update matters and what breaks if you violate it.

**rule_explorer_1d** — An interactive 1D elementary CA renderer. A slider selects any rule from 0 to 255. The binary encoding appears alongside the 8-entry lookup table. The automaton runs from a single-cell seed, drawing each generation as a new row — the classic Wolfram triangle. Rule 30, Rule 110, Rule 90 are presets. The learner sees how a single integer — 8 bits — determines whether the output is periodic, chaotic, or complex.

**neighborhood_comparator** — Side-by-side grids running the same rule with von Neumann and Moore neighborhoods. Same initial conditions, same rule logic (adapted for neighbor count range), different connectivity. The learner watches how neighborhood topology shapes the character of emergent patterns — diamond growth versus square growth, different propagation speeds, different stability properties.

**symmetry_seed_editor** — A drawing tool for the top-left quadrant of the persian rug grid. Toggling cells updates all four quadrants in real-time through mirror reflection. The learner designs a seed, then runs the automaton to see how their initial symmetry propagates and elaborates over generations. Connects the abstract idea of "symmetric rules preserve symmetric inputs" to hands-on construction.
