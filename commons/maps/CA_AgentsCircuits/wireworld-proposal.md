# Wireworld — retained development proposal

Archived from this hall’s earlier companion documents on 25 September 2026. These passages describe an intended circuit lesson, not the current two-work comparison gallery. Their code examples and speculative claims are retained for development; they have not been verified as installed encounters. The current implementation is described in technical.md.

---

## Earlier technical.md

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

**rule_comparison_wall** -- A vertical display of all 256 elementary CA rules running simultaneously from the same initial condition. Each rule occupies a narrow column. The columns tile side by side, forming a wall-sized mosaic.

The learner walks along the wall, scanning from Rule 0 (all dead) through Rule 110 (complex) to Rule 255 (all alive). Class I rules produce uniform columns. Class II rules produce striped or periodic columns. Class III rules produce noisy, textured columns. Class IV rules produce columns with visible internal structure — gliders, interactions, localized complexity. The wall makes Wolfram's four-class taxonomy visible at a glance, setting the stage for CA_12's formal classification.

---

## Earlier intent.md

Concept: Wireworld and custom rule exploration — cells as empty, electron head, electron tail, or conductor, enabling logic gates, circuits, and full computers within a cellular automaton. The interactive Wolfram CA explorer lets the learner define and test any rule, closing the sequence with creative agency over the medium.
Sequence role: Twelfth and final map in the Cellular Automata sequence (numbered CA_11); the synthesis and sandbox. Wireworld proves the sequence truth in its most concrete form: a four-state CA can simulate digital logic, meaning cellular automata literally compute. The ca_rule_explorer gives the learner authorship — after eleven maps of encountering predefined rules, the learner now writes their own. The CellularAutomata3DStacked artifact combines the 3D volumetric theme (CA_9) with stacked elementary CA layers, visually summarizing the 1D-to-3D arc of the entire sequence; follows CA_12.
Technical angle: Wireworld (Brian Silverman, 1987): four states — empty, electron head, electron tail, conductor. Rules: head becomes tail, tail becomes conductor, conductor becomes head if exactly 1 or 2 neighbors are heads, empty stays empty. This suffices for AND, OR, NOT gates, clocks, diodes, and full digital circuits. The ca_rule_explorer is an interactive Wolfram-style tool: select rule number (0-255 for elementary, extended for totalistic), set initial conditions, watch evolution. CellularAutomata3DStacked layers elementary CA time-steps into a 3D volume, making the spacetime diagram a navigable solid.
Critical angle: Wireworld is the sequence's capstone argument: cellular automata are not merely analogies for computation — they are computation. A Wireworld computer can run programs, store memory, and perform arithmetic using nothing but neighbor-counting on a grid. The interactive explorer completes the pedagogical arc from passive observation (CA_1) to active creation. The learner leaves the sequence not as a spectator of emergence but as a designer of computational universes. The entropy phase concludes with its proof: local rules, global patterns, and anything is computable.
Key artifacts: CellularAutomata3DStacked layers elementary CA time-steps into a navigable 3D volume; ca_rule_explorer provides an interactive Wolfram CA sandbox for custom rule definition and experimentation.
Gap: Needs a Wireworld circuit library — pre-built logic gates (AND, OR, NOT, XOR) and a clock signal that the learner can wire together, culminating in a simple adder circuit to demonstrate that the four-state CA is genuinely computing arithmetic.

---

## Earlier artifacts.md

# CA AgentsCircuits — Artifacts
*Cellular Automata: Local Rules, Global Patterns · lambda_edge · 3 artifacts*

> Wireworld: cells can be empty, electron head, electron tail, or conductor. Electrons flow along conductor paths, enabling logic gates, circuits, computers. A cellular automaton that can simulate computers. Turing completeness in four colors.

The map, read through what it holds — its artifacts in the order you meet them:

## Cellular Automata Rule Explorer
![Cellular Automata Rule Explorer](/scene-catalog/ca_rule_explorer.png)

Browse and experiment with different cellular automata rule sets in real-time. Dial through Wolfram's elementary rules or configure custom neighborhood and transition tables to discover the full spectrum from dead stillness to chaotic noise, with complexity emerging at the edge.

`ca_rule_explorer`

## CellularAutomata3DStacked
![CellularAutomata3DStacked](/scene-catalog/CellularAutomata3DStacked.png)

layer(n+1) = life_rules(layer(n)) with outward→upward phase transition

`CellularAutomata3DStacked`

## Sierpinski Pyramid
![Sierpinski Pyramid](/scene-catalog/sierpinski_pyramid.png)

Recursive Sierpinski Pyramid construction using cubes.

`sierpinski_pyramid`


---

## Earlier critical.md — speculative research, not established findings

Retained verbatim on 25 September 2026. This earlier essay refers to a proposed Wireworld encounter. Its claims that code confirms philosophical theories or makes fixed political necessities are not conclusions established by the current two-work hall. They remain questions for a future artifact and a separate critical argument.

# The electron does not choose to be an electron — thrownness, agency, and the politics of thresholds tested in four cell states

Every theoretical claim in this document is tested in code. The test is not illustration. It is verification: does the concept survive contact with a transition function? If Heidegger's thrownness is real, it should be expressible as a computational structure. If Barad's agential realism describes something that actually happens, we should be able to find it in a neighbor count. If Butler's performativity is more than metaphor, the refractory tail should demonstrate it mechanically. The code is the experiment. The theory is the hypothesis.

## Thrownness: You Wake Up as HEAD

Heidegger's Geworfenheit — thrownness — names the condition of finding yourself already in a situation you did not choose. You do not first exist and then enter a world. You arrive already entangled, already committed, already decaying.

Test this in Wireworld:

Three of four states have no conditional logic. HEAD becomes TAIL unconditionally. The electron does not consult its neighbors. It does not evaluate options. It transitions because that is what HEAD does. The cell was thrown into HEAD and its trajectory is fixed.

This is not an analogy to thrownness. It is thrownness formalized. The `match` statement IS the ontological structure. HEAD has no branch, no `if`, no consultation of context. Its future is syntactically determined the moment it exists.

Now test the limits of the claim. Heidegger says thrownness is not mere determinism — the thrown being still acts, still projects, still cares. Does the electron head "project"?

Yes. While HEAD decays into TAIL, its presence is counted by neighboring conductors. The electron's existence — its being-there before it vanishes — changes what its neighbors become. HEAD does not choose this effect. It does not aim it. But it projects forward into the grid's future by being counted. The projection is not intentional. It is structural. HEAD affects the world by existing, not by deciding.

Heidegger's distinction survives the code but is transformed by it. In Wireworld, thrownness and projection are not sequential (first thrown, then project). They are simultaneous. HEAD decays AND is counted in the same generation. Being-toward-death and being-for-others are the same computational step. The code collapses a distinction that Heidegger kept separate.

**Verdict:** Thrownness is computationally real. The code confirms the core claim (you don't choose your initial state, your trajectory is given) but collapses the thrown/projected distinction into a single operation. The theory predicted two phases. The code shows one.

## The Refractory Tail: Performativity as Mechanism

Butler's performativity: identity is not expressed but produced through repeated acts. Gender is not something you are but something you do — and critically, the doing constrains what can be done next. Performance creates its own conditions.

The TAIL state is performativity made mechanical:

The test breaks the naive claim. Writing the code reveals that the refractory tail does not enforce directionality on its own. A straight wire propagates in both directions. The TAIL creates asymmetry in *time* (one direction leads by one generation) but not in *space*. Spatial directionality requires the diode — a geometric narrowing that exploits the threshold:

Butler is more right than the naive reading suggested. Performativity is not just repetition — it is repetition *within a spatial structure* that constrains what the repetition produces. The tail's refractory period is necessary but not sufficient for directionality. The diode's geometry is necessary but not sufficient without the tail's delay. Neither state nor structure alone produces the constraint. Both together do.

This is Butler's point precisely: performativity is not a property of the subject (the cell) or the structure (the grid) but of their repeated interaction within a constraining geometry. The code confirms this by failing when you test either component in isolation.

**Verdict:** Performativity is computationally real but requires spatial structure. The code refines the theory: repetition alone is symmetric. Repetition within asymmetric geometry produces directionality. The theory was right about mechanism but underspecified about conditions.

## Agential Realism: The Conductor's Conditional Existence

Barad's agential realism: entities do not pre-exist their interactions. Properties are not possessed but enacted through "intra-actions" — mutual constitutions where the apparatus and the phenomenon are not separable.

The CONDUCTOR state tests this directly:

The test confirms Barad's claim with uncomfortable precision. The conductor cell has no intrinsic disposition toward becoming HEAD. It is not "excitable" as a property. Whether it excites depends entirely on the configuration of its neighborhood at the moment of evaluation. The same cell, the same state, produces different outcomes depending on context. Agency is relational.

But the code also reveals something Barad's framework struggles with: the threshold is absolute. The rule says 1 or 2, not 1 or 2 or maybe 3 depending on the history. The "apparatus" (the transition rule) is not negotiable. It is not produced through interaction. It is given — a fixed constraint that all intra-actions operate within.

**Verdict:** Agential realism is confirmed at the level of cell-neighborhood interaction. Agency is relational, not intrinsic. But the framework hits a limit: the transition rule itself is not relational. It is the fixed infrastructure that enables relational agency to produce determinate outcomes. Full agential realism — where even the rules are produced through interaction — may be incompatible with computation. The code reveals that Barad's ontology requires a non-Baradian foundation to operate.

## The Threshold as Politics

Why does the conductor fire at 1 or 2 HEAD neighbors, but not at 3?

This is not a natural law. Brian Silverman chose this threshold in 1987 because it produces useful behavior — logic gates, directional signals, computation. A different threshold produces a different physics:

Each threshold is a political system. Wireworld's `{1, 2}` is a specific compromise: sensitive enough that single signals propagate (inclusion), restrictive enough that too-many-simultaneous-signals cancel (structure). The diode exploits this boundary — it engineers situations where backward signals produce 3+ heads, pushing the count above the threshold. The diode is a political technology. It manufactures exclusion at a junction.

The OR gate is permissive politics: either voice suffices. The AND gate is consensus politics: both voices required (engineered through timing so both-present = 2 heads, one-present = 3+ heads = cancellation). The NOT gate requires a clock — an imposed rhythm from outside. You cannot negate without institutional time.

Derrida argued that negation presupposes presence — you can only negate what is already posited. The Wireworld clock confirms this computationally. The NOT gate does not create absence from nothing. It suppresses a clock pulse that was already flowing. Negation is subtraction from a ground signal, not creation ex nihilo. The clock must exist before the NOT gate can mean anything.

**Verdict:** The threshold is political, not natural. The code proves this by showing that five different thresholds produce five different social physics — from anarchy (everything propagates) to autocracy (only lone voices survive). Wireworld's specific threshold enables computation because it balances inclusion and exclusion. The code also confirms Derrida's insight about negation: NOT requires institutional infrastructure (the clock) and operates by suppression of presence, not production of absence.

## QFEP: Where Is Lambda?

The Queer Free Energy Principle: **QFE = F - λE(S) + φΔE(S,t)**

Where does each term live in Wireworld?

This is the deep result. Wireworld computes BECAUSE lambda is zero. Introduce exploration (λ > 0) and gates become unreliable. Introduce positive phi (embrace change) and the refractory period dissolves, backward propagation occurs, signals collide unpredictably.

Computation requires conservatism. The circuit must be frozen. The rules must be fixed. The signals must be deterministic. This is not a political choice — it is a mathematical necessity. Universal computation, as Wireworld demonstrates it, requires λ ≈ 0 and φ < 0.

But CA_10's ant highway was the opposite. The ant explored (λ > 0). The highway emerged from that exploration. The highway was not designed. It was found through entropy-driven search. The ant cannot compute, but it can discover. Wireworld computes but cannot discover.

**Verdict:** QFEP locates Wireworld precisely. It is a low-lambda, negative-phi system: pure order, resistance to change, no exploration. This is what makes it useful for engineering and useless for discovery. The code test reveals that the CA sequence has been a journey along the lambda axis — from the edge of chaos (Rule 110, Life) through exploration (Langton's Ant) to crystallized order (Wireworld). The QFEP framework predicts exactly where each system sits and why.

## Design Coexisting with Emergence: The Collapse of the Binary

Every previous CA in the sequence demonstrated pure emergence — complex behavior that nobody designed. Wireworld inverts this. The rules are still local and uniform (emergence infrastructure). But the circuit layout is intentional (design). The electron's path through a wire is emergent. The wire's placement is designed.

This dissolves a binary that has structured the entire sequence. Emergence vs design. Found vs made. CA_1 through CA_10 said: simple rules produce complexity nobody designed. CA_11 says: simple rules PLUS designed geometry produce computation that neither the rules nor the geometry contain alone.

The AND gate is the proof. No single conductor cell "knows" it is part of an AND gate. No single rule "intends" conjunction. The AND operation emerges from the spatial relationship between conductors, the timing of signals, and the threshold. Remove any one component and the AND gate fails. The computation is distributed across rule, geometry, and time.

This is Barad's "intra-action" at the system level: the phenomenon (computation) does not pre-exist the apparatus (rule + layout + signal). It is produced through their entanglement. But unlike Barad's framework, we can specify exactly which components contribute what and test each one in isolation. The code lets us do controlled experiments on ontological claims.

**Verdict:** Emergence and design are not opposites. They are layers that interact to produce phenomena (computation) that neither contains alone. The code confirms this by showing that an AND gate requires both fixed rules and intentional geometry but is reducible to neither.

## The ca_rule_explorer: Agency After Understanding

The explorer shifts the learner from spectator to author. After eleven maps of observing rules, the learner writes their own. This is not a pedagogical convenience. It is the theoretical payoff.

The 256-rule space is navigable but not designable. The learner cannot say "I want a rule that produces gliders" and derive the rule number. They must explore — try rules, observe outputs, build intuition. This is lambda > 0 behavior: the learner searches through possibility space, guided by curiosity and pattern recognition, not by deduction.

The explorer makes the learner into Langton's ant. The ant could not compute, but it could discover. The learner, moving through the rule space, is doing the same thing: exploring a vast space of possibilities, finding structure through iteration, unable to predict what each step will produce.

The sequence ends where it began — with exploration. But the learner now understands what they are exploring, and why some rules compute while others merely pattern. That understanding is the difference between the ant and the engineer. Both explore. One knows what it is looking for.

## Summary of Tests

| Claim | Source | Code Test | Verdict |
|-------|--------|-----------|---------|
| Thrownness: you don't choose initial conditions | Heidegger | HEAD has no conditional logic; trajectory is given | **Confirmed.** But thrown/projected distinction collapses — both happen in one tick |
| Performativity: identity through constrained repetition | Butler | TAIL blocks backward propagation — but only with diode geometry | **Refined.** Repetition alone is symmetric; asymmetric geometry required |
| Agential realism: agency is relational | Barad | Conductor's next state depends entirely on neighborhood | **Confirmed with limit.** Agency is relational but the transition rule is not |
| Threshold as politics | Critical theory | Five different thresholds produce five different social physics | **Confirmed.** Wireworld's threshold is a specific political compromise |
| Negation requires infrastructure | Derrida | NOT gate requires clock; negation is suppression of presence | **Confirmed.** You cannot say "not" without a heartbeat |
| QFEP locates computational systems | QFEP | Wireworld is λ≈0, φ<0; computation requires suppressed exploration | **Confirmed.** Reliable computation clusters at low lambda |
| Emergence vs design is false binary | Systems theory | AND gate requires both fixed rules and intentional geometry | **Confirmed.** Neither layer alone produces computation |

Each claim was tested by writing code that either confirms, refines, or breaks it. Four were confirmed. Two were refined — the code revealed additional conditions the theory did not specify. None were fully broken, but agential realism hit a structural limit: the transition rules themselves are not relationally produced.

The method: make a theoretical claim, write a function that tests it, run the function, report what happened. Theory as hypothesis, code as experiment.
