# Electrons flow through conductor wires on a four-state grid where the simplest possible circuit proves that cellular automata literally compute

CA_10 introduced the agent. One ant, one grid, two rules — and a highway that nobody programmed. The emergence was powerful but narrow. The ant built a single repeating structure. It could not store a bit, route a signal, or evaluate a condition. The highway proved that simple rules produce complex output. It did not prove that simple rules compute.

CA_11 closes that gap. Wireworld replaces the ant's binary grid with four cell states — empty, electron head, electron tail, conductor — and the result is not emergence. It is engineering. Logic gates, clocks, diodes, memory, arithmetic. A cellular automaton that runs programs. The sequence truth arrives in its most literal form: local rules, applied uniformly, are sufficient for universal computation. The ca_rule_explorer then hands the learner the keys. After eleven maps of observing predefined rules, the learner writes their own.

## Four States, Three Rules

Wireworld (Brian Silverman, 1987) operates on a 2D grid. Each cell holds one of four states: empty (0), electron head (1), electron tail (2), conductor (3). The update rules are exhaustive and unambiguous:

1. Empty stays empty.
2. Electron head becomes electron tail.

3. Electron tail becomes conductor.
4. Conductor becomes electron head if exactly 1 or 2 of its eight Moore neighbors are electron heads. Otherwise it remains conductor.

```gdscript
enum CellState { EMPTY, HEAD, TAIL, CONDUCTOR }

func wireworld_step(grid: Array, width: int, height: int) -> Array:
    var next: Array = []
    for y in range(height):
        var row: Array = []
        for x in range(width):
            var current: int = grid[y][x]
            match current:
                CellState.EMPTY:
                    row.append(CellState.EMPTY)
                CellState.HEAD:
                    row.append(CellState.TAIL)
                CellState.TAIL:
                    row.append(CellState.CONDUCTOR)
                CellState.CONDUCTOR:
                    var heads := count_head_neighbors(grid, x, y, width, height)
                    if heads == 1 or heads == 2:
                        row.append(CellState.HEAD)
                    else:
                        row.append(CellState.CONDUCTOR)
        next.append(row)
    return next
```

Three of the four rules are unconditional. Empty maps to empty — no exceptions. Head maps to tail — no exceptions. Tail maps to conductor — no exceptions. Only the conductor rule consults the neighborhood, and even then it asks a single question: are exactly 1 or 2 neighbors heads? The entire transition function fits in a `match` block with four arms. The neighbor count requires a loop. Everything else is constant-time lookup.

The head-to-tail-to-conductor cascade makes signal propagation work. A head excites adjacent conductors, then becomes a tail. The tail is a refractory period — it blocks backward propagation because tails do not count as heads in the neighbor check. One generation later the tail becomes conductor, ready for the next signal. The three-state cycle creates a directional pulse that travels along any conductor path at one cell per generation.

```gdscript
func count_head_neighbors(grid: Array, cx: int, cy: int,
                          width: int, height: int) -> int:
    var count: int = 0
    for dy in range(-1, 2):
        for dx in range(-1, 2):
            if dx == 0 and dy == 0:
                continue
            var nx := cx + dx
            var ny := cy + dy
            if nx >= 0 and nx < width and ny >= 0 and ny < height:
                if grid[ny][nx] == CellState.HEAD:
                    count += 1
    return count
```

No wrapping here. Wireworld grids typically use bounded edges rather than toroidal wrapping — signals that reach the boundary stop. The boundary acts as a natural terminator. In circuit design terms, an unwired edge is an open connection. Signals dissipate at open connections. This is correct behavior, not a limitation.

The bounded-edge choice contrasts with CA_4's toroidal wrapping. In a totalistic Life variant, wrapping ensures every cell has the same neighbor count — uniformity matters when the rule is statistical. In Wireworld, the rule is structural. Conductor paths are laid deliberately. Signals travel where wires go and nowhere else. An edge without a wire is not a missing neighbor. It is an absent connection. The grid boundary and an unwired cell are functionally identical: empty stays empty.

## Signal Propagation and the Refractory Tail

Place a line of conductor cells. Set the leftmost cell to electron head and its right neighbor to electron tail. Run the simulation.

```gdscript
# A straight wire: 10 conductor cells with a signal at the left end
func create_wire(grid: Array, start_x: int, y: int, length: int) -> void:
    for i in range(length):
        grid[y][start_x + i] = CellState.CONDUCTOR
    # Inject a signal: head followed by tail
    grid[y][start_x] = CellState.HEAD
    grid[y][start_x + 1] = CellState.TAIL
```

The signal advances one cell per generation, leaving a trail of tail then conductor behind it. The pulse moves right at speed 1. It cannot reverse because the trailing tail is not a head — the refractory state blocks backward excitation.

This is not an analogy to electrical signal propagation. It is signal propagation. The conductor path is a wire. The electron head is a voltage pulse.

The tail is the recovery period. Propagation speed is fixed at one cell per generation — the automaton's speed of light. Timing is deterministic and distance-dependent: a signal traveling 5 cells arrives exactly 5 generations after injection. Wire length is delay. Delay is computable.

## Logic Gates from Geometry

The conductor-becomes-head rule fires when exactly 1 or 2 neighbors are heads. This threshold creates the logic. A conductor cell at a junction where two wires meet can receive 0, 1, or 2 head neighbors simultaneously. At 0 heads: no signal, the conductor stays conductor. At 1 head: one input is active, the conductor fires. At 2 heads: both inputs are active, the conductor fires. At 3 or more heads: the conductor does not fire — the signals cancel.

An OR gate is a Y-junction. Two input wires merge into one output wire. If either input carries a signal, the junction cell sees 1 head and fires. If both inputs carry signals simultaneously, it sees 2 heads and fires. Output is active when at least one input is active. OR.

```gdscript
func create_or_gate(grid: Array, junction_x: int, junction_y: int) -> void:
    # Two input wires converging on a single junction cell
    # Input A: horizontal wire from the left
    for i in range(5):
        grid[junction_y][junction_x - 5 + i] = CellState.CONDUCTOR
    # Input B: diagonal wire from upper-left
    for i in range(5):
        grid[junction_y - 5 + i][junction_x - 5 + i] = CellState.CONDUCTOR
    # Junction and output wire
    grid[junction_y][junction_x] = CellState.CONDUCTOR
    for i in range(1, 6):
        grid[junction_y][junction_x + i] = CellState.CONDUCTOR
```

An AND gate requires more geometry. The two inputs must arrive at a conductor cell that fires only when both are present. Since the rule fires at 1 or 2 heads, a simple merge cannot distinguish "one input" from "both inputs." The solution uses signal timing and path geometry to ensure that a single input's signal reaches the output junction with a neighbor count of 3 or more (suppressed), while two simultaneous inputs produce exactly 1 or 2 heads at the critical cell. The exact layout varies — multiple AND gate designs exist in Wireworld, each exploiting different timing relationships.

A NOT gate (inverter) requires a clock — a continuous stream of pulses. The input signal suppresses one clock pulse at a junction. When the input is absent, the clock pulse passes through. When the input is present, the clock pulse and the input signal arrive at the same junction with 3 or more heads, suppressing output. Absence of input produces output. Presence of input suppresses output. Inversion.

The clock itself is a loop of conductor cells with a circulating electron. A loop of length N produces one pulse every N generations. The pulse travels the loop indefinitely — head becomes tail becomes conductor, and the head has moved one cell forward, forever. The loop is a ring oscillator. Its period is its circumference.

```gdscript
func create_clock(grid: Array, center_x: int, center_y: int,
                  loop_length: int) -> void:
    # A rectangular loop of conductor cells
    var half := loop_length / 4
    for i in range(half):
        grid[center_y - half / 2][center_x - half / 2 + i] = CellState.CONDUCTOR
        grid[center_y + half / 2][center_x - half / 2 + i] = CellState.CONDUCTOR
        grid[center_y - half / 2 + i][center_x - half / 2] = CellState.CONDUCTOR
        grid[center_y - half / 2 + i][center_x + half / 2] = CellState.CONDUCTOR
    # Inject one electron into the loop
    grid[center_y - half / 2][center_x - half / 2] = CellState.HEAD
    grid[center_y - half / 2][center_x - half / 2 + 1] = CellState.TAIL
```

The clock is the heartbeat. Without it, Wireworld circuits are purely reactive. With a clock, circuits generate signals autonomously — enabling sequential logic, memory, and control flow. Combinational logic (AND, OR) is stateless. Sequential logic (flip-flops, counters) is stateful. The clock is the boundary between them.

## Diodes and Signal Routing

A diode permits signal flow in one direction and blocks it in the other. In Wireworld, a diode is a narrowing: a conductor path passes through a single-cell bottleneck. A signal from the wide side reaches the bottleneck with 1 head neighbor — it passes. A signal from the narrow side fans into the wider section, creating multiple simultaneous heads that exceed the threshold of 2, suppressing propagation. The geometry filters directionality.

```gdscript
func create_diode(grid: Array, x: int, y: int, direction: int) -> void:
    # Wide side: 3-cell-wide conductor
    for dy in range(-1, 2):
        grid[y + dy][x] = CellState.CONDUCTOR
        grid[y + dy][x + 1] = CellState.CONDUCTOR
    # Bottleneck: single cell
    grid[y][x + 2] = CellState.CONDUCTOR
    # Narrow side continues as single-width wire
    for i in range(3, 8):
        grid[y][x + i] = CellState.CONDUCTOR
```

The diode is purely geometric. No new rules. No special cell states. The same four states and three rules that govern every other structure also govern the diode. The asymmetry is spatial, not logical.

This is the recurring pattern in Wireworld: all functional elements — gates, clocks, diodes, memory — arise from the spatial arrangement of conductor cells, not from any variation in the rules. The rules are uniform. The circuits are geometry. A Wireworld designer works in the same medium as the electrons. There is no metalayer, no configuration file, no parameter that distinguishes a wire from a gate. The distinction lives in the topology of conductor paths. Rearrange the same cells and the function changes. The medium is the message.

## From Gates to Computation

AND, OR, and NOT are functionally complete. Any Boolean function can be constructed from combinations of these three gates. Wireworld provides all three. Therefore Wireworld can implement any Boolean circuit. Boolean circuits can compute any finite function. With the addition of memory (flip-flops built from cross-coupled gates) and a clock, Wireworld circuits become sequential machines — finite state automata capable of stepping through programs.

The leap to universal computation requires unbounded memory. A Wireworld computer built by David Moore and Mark Owen demonstrates this in practice: a full CPU with arithmetic logic unit, program counter, instruction register, and addressable memory, implemented entirely in Wireworld cells. The computer executes a stored program. It adds, subtracts, branches, loops. It is slow — one instruction takes thousands of Wireworld generations. It is large — the circuit occupies tens of thousands of cells. But it computes.

This is the sequence's capstone claim. CA_1 showed that a 1D binary automaton (Rule 110) is Turing complete — capable of universal computation. The proof was theoretical, relying on the equivalence between Rule 110 dynamics and tag systems. Wireworld makes the claim visceral.

The logic gates are visible. The signals are traceable. The clock pulses are countable. The computation is not hidden inside an abstract equivalence proof. It is running on the grid, and the learner can watch the electrons flow through the wires, merge at junctions, and produce output.

## The ca_rule_explorer Artifact

The `ca_rule_explorer` shifts from observation to authorship. It is an interactive Wolfram-style tool for elementary cellular automata — the 1D, two-state, radius-1 automata from CA_1. The learner selects a rule number (0 through 255), sets initial conditions, and watches the spacetime diagram unfold.

```gdscript
@export var rule_number: int = 110
@export var grid_width: int = 128
@export var generations: int = 64

var rule_table: Array[int] = []

func build_rule_table(rule_num: int) -> void:
    rule_table.clear()
    for i in range(8):
        rule_table.append((rule_num >> i) & 1)

func apply_rule(left: int, center: int, right: int) -> int:
    var index: int = (left << 2) | (center << 1) | right
    return rule_table[index]
```

The rule number encodes the entire transition table as an 8-bit integer. Each bit corresponds to one of the 8 possible neighborhood configurations (3 cells, 2 states each). The bit-shift extraction `(rule_num >> i) & 1` reads bit `i` from the rule number. The neighborhood index `(left << 2) | (center << 1) | right` packs three binary cells into a 3-bit integer. The lookup is a single array access. No conditionals. No branching. The entire automaton is a table lookup.

```gdscript
func generate_spacetime(initial: Array[int]) -> Array:
    var spacetime: Array = [initial.duplicate()]
    var current := initial.duplicate()
    for gen in range(1, generations):
        var next: Array[int] = []
        for x in range(grid_width):
            var left: int = current[posmod(x - 1, grid_width)]
            var center: int = current[x]
            var right: int = current[posmod(x + 1, grid_width)]
            next.append(apply_rule(left, center, right))
        spacetime.append(next)
        current = next
    return spacetime
```

The spacetime diagram is a 2D grid where the horizontal axis is space and the vertical axis is time. Each row is one generation. The complete diagram is the automaton's history — its trajectory through configuration space rendered as a static image. Rule 30 produces chaos.

Rule 110 produces gliders and localized structures. Rule 90 produces the Sierpinski triangle. Rule 0 kills everything. Rule 255 fills everything. The 256 rules span the full range of dynamical behavior, from death to order to chaos to computation.

The explorer makes the rule space navigable. The learner types a number, watches the result, adjusts, repeats. The feedback loop is immediate. Patterns that took Wolfram years to catalog become discoverable in minutes.

Initial conditions matter. A single active cell in the center produces symmetric output for most rules — the spacetime diagram fans outward like a triangle. A random initial row breaks the symmetry and reveals the rule's response to disorder. Rule 110 produces gliders from a single seed but produces complex interactions — collisions, annihilations, particle-like dynamics — from a random seed. The same rule, different inputs, qualitatively different outputs. The explorer exposes this by letting the learner toggle between single-seed and random initialization.

The rule number is the program. The initial condition is the input. The spacetime diagram is the output. The explorer is a compiler for one-dimensional universes.

## CellularAutomata3DStacked: The Spacetime Solid

The `CellularAutomata3DStacked` artifact layers elementary CA time-steps into a 3D volume. Each horizontal slice is one generation. The vertical axis is time. The spacetime diagram — normally a flat image — becomes a navigable solid.

```gdscript
@export var rule_number: int = 110
@export var ca_width: int = 64
@export var num_layers: int = 32
@export var layer_spacing: float = 0.2
@export var cell_size: float = 0.15

func build_stacked_volume() -> void:
    var spacetime := generate_spacetime_from_rule(rule_number, ca_width, num_layers)
    for gen in range(num_layers):
        for x in range(ca_width):
            if spacetime[gen][x] == 1:
                var pos := Vector3(
                    (x - ca_width / 2.0) * cell_size,
                    gen * layer_spacing,
                    0.0
                )
                spawn_cell_block(pos, gen, x)
```

The x-coordinate maps spatial position. The y-coordinate maps time. A glider in the elementary CA — a pattern that translates laterally over successive generations — becomes a diagonal column in the 3D solid. A static structure becomes a vertical pillar. An oscillator becomes a repeating pattern along the y-axis. The temporal behavior of the 1D automaton is frozen into the spatial structure of a 3D object.

Walk around Rule 110 and the gliders are diagonal tubes punching through the volume. Peer into Rule 90 and the Sierpinski triangle is a lattice of voids — a solid with fractal holes. Rule 30's chaos becomes an opaque, disordered mass with no visible internal structure. The character of each rule is legible in the shape of its solid.

This artifact connects the 1D-to-3D arc of the entire sequence. CA_1 introduced elementary automata as flat spacetime diagrams. CA_9 explored full 3D volumetric automata. The stacked artifact bridges both: a 1D automaton visualized as a 3D volume, using time as the third dimension. The spacetime diagram is not a picture. It is a solid with depth, structure, and navigable interiors — the same claim CA_9 made about 3D automata, realized here through temporal stacking rather than spatial simulation.

## The Sandbox and the Proof

Wireworld and the rule explorer occupy opposite ends of the spectrum. Wireworld is a specific four-state automaton with fixed rules. The rule explorer is a general-purpose tool for 256 different automata with adjustable rules. Wireworld proves that cellular automata compute by constructing circuits. The rule explorer proves that the space of automata is vast, varied, and worth exploring.

Together they close the sequence. CA_1 through CA_10 presented cellular automata as objects of study — here are the rules, here is what happens, watch. CA_11 presents cellular automata as objects of creation. The Wireworld circuits are designed, not discovered. The explorer rules are chosen, not given.

The learner's role shifts from spectator to architect. The passive verb — "watch the automaton evolve" — gives way to the active — "build a circuit," "choose a rule," "test a hypothesis." The tools exist. The understanding exists. What remains is agency.

The shift resolves a tension that has built across eleven maps. Every previous map demonstrated emergence — complex behavior from simple rules that nobody designed. Wireworld inverts this. The rules are still simple. The micro behavior is still emergent — each electron steps according to four states and three transitions.

But the macro behavior is designed. The circuit layout is intentional. Emergence and design coexist. Transistors obey physics. Chips are engineered. The two scales cooperate.

The learner leaves CA_11 with two capabilities: the understanding that four cell states suffice for digital logic, and the tools to define and test arbitrary rules. The sequence truth is no longer a claim to be accepted. It is a fact to be verified, a tool to be wielded, and a sandbox to be explored.

## Possible Artifacts

**wireworld_circuit_library** -- A collection of pre-built Wireworld components: AND gate, OR gate, NOT gate (with clock), XOR gate, diode, signal splitter, and a clock loop. Each component is a self-contained grid region that the learner places and wires together by drawing conductor paths between them. A half-adder circuit (XOR + AND) demonstrates single-bit addition. A full-adder chains two half-adders with a carry line. The learner watches binary addition happen one electron at a time — two input signals enter, a sum signal and a carry signal exit. Arithmetic from geometry.

**wireworld_sandbox** -- A blank conductor grid with a palette of the four cell states. The learner draws circuits freehand: lay conductor paths, place electron heads to inject signals, and run the simulation. A toolbar provides undo, clear, and step-by-step advance. Speed controls range from single-step (one generation per click) to continuous (60 generations per second). The sandbox is the complement to the circuit library — where the library provides structure, the sandbox provides freedom.

**rule_comparison_wall** -- A vertical display of all 256 elementary CA rules running simultaneously from the same initial condition. Each rule occupies a narrow column. The columns tile side by side, forming a wall-sized mosaic. The learner walks along the wall, scanning from Rule 0 (all dead) through Rule 110 (complex) to Rule 255 (all alive). Class I rules produce uniform columns. Class II rules produce striped or periodic columns. Class III rules produce noisy, textured columns. Class IV rules produce columns with visible internal structure — gliders, interactions, localized complexity. The wall makes Wolfram's four-class taxonomy visible at a glance, setting the stage for CA_12's formal classification.
