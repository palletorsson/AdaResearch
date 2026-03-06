# Cells carry intensity across a petri dish where decay trails and mold tendrils replace the binary flicker of totalistic grids

CA_4 compressed the rule table. Nine neighbors collapsed into one sum, and the automaton forgot which direction influence arrived from. But every cell still held the same two values: on or off, alive or dead, 1 or 0. The sum was richer; the states were not. CA_5 breaks that constraint. Cells now hold integers from 0 to k-1, where k can be 3, 5, 16, 256. A cell is no longer a switch. It is a dial.

The consequences are immediate. A binary cell has no past — it is alive or dead, and the grid cannot tell how long it has been either. A multi-state cell carries a gradient. A cell at intensity 7 that was at intensity 9 last generation has decayed. The current value encodes history implicitly. The grid acquires memory without any explicit memory mechanism.

Two states give you logic. Many states give you thermodynamics.

## k-State Automata

A k-state automaton assigns each cell an integer in the range [0, k-1]. The transition function maps the cell's current state and its neighborhood sum to a new state. For binary automata, k = 2 and there are two outcomes per input configuration. For k = 8, there are eight possible next states per configuration. The rule table grows, but the structure remains the same: current state plus neighborhood context produces next state.

```gdscript
@export var num_states: int = 8
@export var grid_width: int = 48
@export var grid_height: int = 48

var grid: Array = []
var next_grid: Array = []

func _initialize_grid() -> void:
    grid.resize(grid_width * grid_height)
    next_grid.resize(grid_width * grid_height)
    for i in range(grid.size()):
        grid[i] = 0
    # Seed a cluster near the center
    var cx := grid_width / 2
    var cy := grid_height / 2
    for dx in range(-3, 4):
        for dy in range(-3, 4):
            var idx := (cy + dy) * grid_width + (cx + dx)
            grid[idx] = randi() % num_states
```

The grid is flat — a one-dimensional array indexed by `y * width + x`. Each cell stores an integer, not a boolean. The seed cluster near the center receives random state values across the full range. From the first frame, the grid contains a spectrum, not a binary scatter.

The initialization matters. A grid seeded entirely at state 0 with a single nonzero cell produces clean wavefront dynamics — one excitation expanding outward. A grid seeded with random values across the full range produces turbulence from the first generation — every cell reacts to neighbors in every possible state simultaneously. Same rules, different seeds, different behavior classes.

The number k is a design parameter. Small k (3 or 4) produces automata where state transitions are legible — the learner can track which cells are decaying, which are activating. Large k (64, 256) produces fields that look continuous. The cells are still discrete integers, but the visual gradient smooths into something resembling a diffusion simulation.

Discrete substrate, continuous appearance. The gap between the two narrows as k increases but never closes.

## Decay: States That Remember

Decay is the simplest multi-state mechanic. An active cell does not switch off instantly. It steps down through intermediate values: maximum state to maximum minus one, then minus two, continuing until it reaches zero. The cell cools. The trail it leaves behind — a gradient of fading intensities — records where activity has been.

```gdscript
@export var decay_rate: int = 1
@export var activation_threshold: int = 3

func _apply_decay_rule(cell_state: int, neighbor_sum: int) -> int:
    if cell_state == 0:
        # Dead cell: activate if neighbor sum crosses threshold
        if neighbor_sum >= activation_threshold:
            return num_states - 1  # Full intensity
        return 0
    else:
        # Active cell: decay toward zero
        return maxi(cell_state - decay_rate, 0)
```

The rule splits into two cases. A cell at state 0 is resting — it can be excited by sufficient neighbor activity, jumping to maximum intensity. A cell at any nonzero state is decaying — it loses `decay_rate` per generation regardless of its neighbors. The decay is unconditional. Once excited, the cell is committed to a countdown.

This creates a refractory period. A cell that has just fired sits at state k-1 and begins decaying. It cannot be re-excited until it returns to 0. The higher k is, the longer the refractory period, and the further apart successive waves of activation must travel. The spacing between wavefronts becomes a function of k.

The state count controls temporal rhythm.

Consider the `decay_rate` parameter. At `decay_rate = 1`, a cell with k = 8 takes seven generations to recover. At `decay_rate = 2`, it takes four. The refractory period equals `ceil((k - 1) / decay_rate)`. Faster decay means faster recovery, tighter wavefront spacing, denser patterns. The two parameters — k and `decay_rate` — interact multiplicatively. Tuning them independently reveals which visual features depend on state count and which depend on recovery time.

The `game_of_life_petri` artifact in this map uses decay to extend Life-like rules. Birth and survival thresholds still apply, but activated cells do not simply persist — they blaze at full intensity and then fade through the state gradient. The petri dish surface shows this as luminous wavefronts followed by dimming trails. The effect resembles bioluminescence: a bright flash propagating outward, darkness recovering behind it.

```gdscript
func _petri_step(delta: float) -> void:
    for y in range(grid_height):
        for x in range(grid_width):
            var idx := y * grid_width + x
            var current := grid[idx]
            var alive_neighbors := _count_alive_neighbors(x, y)
            next_grid[idx] = _apply_decay_rule(current, alive_neighbors)
    # Swap buffers
    var temp := grid
    grid = next_grid
    next_grid = temp
```

Double buffering prevents read-write conflicts. Every cell reads from `grid` and writes to `next_grid`. After all cells update, the buffers swap. The same technique from binary CA applies unchanged — multi-state automata do not require a different update architecture. The data widens (integers instead of booleans), but the synchronization pattern holds.

## Excitable Media and the Greenberg-Hastings Model

Decay automata model excitable media — systems where elements rest, fire, recover, and can fire again. The canonical example is the Greenberg-Hastings model: three logical phases mapped onto k discrete states.

Phase 0: Resting (state = 0). The cell waits. If a neighbor is at maximum intensity (recently fired), the resting cell activates.

Phase 1: Excited (state = k-1). The cell has just fired. It is at peak intensity. Neighboring resting cells may respond.

Phase 2: Refractory (states k-2 down to 1). The cell is recovering. It cannot be re-excited. It decays one step per generation until it reaches 0 and re-enters the resting phase.

```gdscript
func _greenberg_hastings_rule(cell_state: int, has_excited_neighbor: bool) -> int:
    if cell_state == 0:
        if has_excited_neighbor:
            return num_states - 1
        return 0
    else:
        return cell_state - 1
```

Three lines of logic produce spiral waves. On a two-dimensional grid, a single excited cell triggers its neighbors, which trigger theirs, creating an expanding ring. But the cells behind the wavefront are refractory — the wave cannot propagate backward. The ring expands outward only.

If the initial excitation is asymmetric (a broken wavefront rather than a perfect circle), the wave curls around its own refractory tail, forming a rotating spiral. The spiral is self-sustaining. It feeds on resting cells ahead and is blocked by refractory cells behind.

Cardiac tissue operates on this principle. The electrical impulse that triggers a heartbeat is a spiral wave in excitable media. Spiral breakup — when one spiral fragments into many — corresponds to fibrillation. The Greenberg-Hastings model captures this dynamic with a rule that fits in a single function.

The neighbor check in the Greenberg-Hastings rule is binary: does any neighbor hold the maximum state? This differs from totalistic counting. CA_4 asked "how many neighbors are alive?" The excitable rule asks "is any neighbor excited?" The threshold is 1 and the comparison targets a specific state value, not a sum. Totalistic rules produce density-dependent behavior. Excitable rules produce contact-dependent behavior. One counts. The other detects.

## Cyclic Automata: States That Rotate

Decay flows in one direction: high to low, active to resting. Cyclic automata close the loop. State 0 is consumed by state 1, state 1 by state 2, and state k-1 by state 0. Each state "eats" the one below it in a circular hierarchy. There is no resting phase. Every state is simultaneously predator and prey.

```gdscript
func _cyclic_rule(cell_state: int, x: int, y: int) -> int:
    var next_state := (cell_state + 1) % num_states
    # Check if any neighbor has the state that eats this one
    for neighbor in _get_neighbors(x, y):
        if grid[neighbor] == next_state:
            return next_state
    return cell_state
```

A cell advances to the next state only if at least one neighbor already holds that state. Advancement requires contact with the predator. Without it, the cell remains static.

This creates a competition dynamic: clusters of state 0 are invaded by state 1 at their borders, state 1 clusters are invaded by state 2, and so on. The boundaries between state regions become the active zones — spiral fronts that rotate through the color cycle.

The visual result is striking. Where decay automata produce dimming trails, cyclic automata produce rainbow spirals. Each state maps to a hue. The spirals rotate continuously, neither growing nor shrinking, in a dynamic equilibrium. The system has no fixed points and no absorbing states. It cycles forever.

Decay is irreversible — a cell at state 3 was once at state 7 and is heading toward 0. Cyclic automata are locally reversible — a cell at state 3 might advance to 4 or stay at 3, and the sequence 0-1-2-...-k-1-0 is a closed orbit. The two models produce visually and dynamically distinct behaviors from the same framework of k discrete states and neighbor-dependent transitions. The difference is whether the state space has an endpoint or a loop.

The modular arithmetic in the cyclic rule — `(cell_state + 1) % num_states` — is the mechanism that closes the loop. Without the modulo, state k-1 would attempt to advance to state k, which does not exist. The modulo wraps it back to 0. One operator converts a linear countdown into a circular orbit. The topology of the state space changes from a line segment to a ring, and the dynamics shift from dissipative to conservative.

## Intensity as Visual Encoding

Multi-state values map naturally to visual properties. The `game_of_life_petri` maps cell state to emission intensity:

```gdscript
func _update_cell_visual(idx: int) -> void:
    var state := grid[idx]
    var t := float(state) / float(num_states - 1)
    # Map normalized state to color intensity
    var color := Color(t * 0.4, t * 0.9, t * 0.6)
    color.a = 1.0
    _set_cell_material_emission(idx, color, t * 2.0)
```

The state integer normalizes to a float in [0, 1]. That float drives color channels and emission energy. State 0 is dark — the cell is resting. State k-1 is brightest — the cell has just fired. Intermediate states produce intermediate glow. The discrete integer becomes a continuous-looking gradient because the eye interpolates between neighboring cells.

This is not cosmetic. The visual encoding is the primary feedback channel. A learner watching the petri dish sees wavefronts as bright advancing edges and refractory zones as dim trailing regions. The brightness gradient communicates the automaton's temporal structure — how long ago each cell fired — without requiring any explicit timeline display.

The state variable is both computational datum and visual signal.

The color channels separate concerns. The green channel dominates (`t * 0.9`), carrying the primary intensity information. The blue channel (`t * 0.6`) provides a cooler undertone at mid-intensities. The red channel (`t * 0.4`) adds warmth at high states. Freshly excited cells glow warm-white. Decaying cells shift toward cool green. Resting cells are dark. The color trajectory encodes the decay timeline as a hue shift, adding a second visual dimension beyond brightness alone.

## The Mold Network: Branching Growth

The `mold_network` artifact departs from the uniform grid. It models branching growth inspired by slime mold (Physarum polycephalum), where agents deposit intensity on a shared CA substrate and steer toward regions of high concentration. The substrate is a multi-state grid. The agents are entities that move across it, sensing and modifying cell values.

```gdscript
@export var num_agents: int = 200
@export var sensor_angle: float = 0.4
@export var sensor_distance: float = 4.0
@export var deposit_amount: int = 5
@export var evaporation_rate: int = 1

func _agent_step(agent: Dictionary) -> void:
    # Sample intensity at three forward positions
    var forward := _sample_at(agent.position, agent.heading, 0.0)
    var left := _sample_at(agent.position, agent.heading, sensor_angle)
    var right := _sample_at(agent.position, agent.heading, -sensor_angle)

    # Steer toward highest intensity
    if forward >= left and forward >= right:
        pass  # Continue straight
    elif left > right:
        agent.heading += sensor_angle * 0.5
    else:
        agent.heading -= sensor_angle * 0.5

    # Move forward
    agent.position.x += cos(agent.heading) * 1.0
    agent.position.y += sin(agent.heading) * 1.0

    # Deposit intensity
    var idx := _position_to_index(agent.position)
    if idx >= 0:
        grid[idx] = mini(grid[idx] + deposit_amount, num_states - 1)
```

Each agent samples intensity at three points: ahead, left-of-ahead, right-of-ahead. It turns toward the strongest signal. Then it moves forward and deposits intensity at its new position. The deposit raises the cell's state value. Evaporation (global decay applied every step) lowers all cell values by `evaporation_rate`. The balance between deposit and evaporation determines whether trails persist or vanish.

When many agents follow this rule simultaneously, they self-organize into networks. Agents reinforce each other's trails — a path with more traffic accumulates more intensity, attracting more agents, accumulating more intensity. Positive feedback creates trunk lines. Branches form where small groups of agents wander off the main path and establish secondary trails.

The result is a network topology that resembles mycelium, river deltas, and vascular systems.

The multi-state grid is essential. A binary grid cannot represent trail strength — a cell is either marked or not. A k-state grid encodes how heavily a cell has been visited. High-intensity cells are highways. Low-intensity cells are footpaths about to evaporate. The gradient gives agents graded information rather than binary signals, enabling proportional steering rather than all-or-nothing attraction.

State depth produces behavioral nuance.

The sensor parameters shape the network geometry. A wide `sensor_angle` produces broad, sweeping networks — agents explore more territory per step. A narrow angle produces tight, linear filaments — agents follow existing trails closely. The `sensor_distance` controls how far ahead the agent looks. Long-range sensing creates smooth curves. Short-range sensing creates jagged paths with frequent direction changes.

The parameters do not change the rule — they change the scale at which the rule operates, and the resulting network structure reflects that scale.

```gdscript
func _evaporate() -> void:
    for i in range(grid.size()):
        grid[i] = maxi(grid[i] - evaporation_rate, 0)
```

Evaporation is global decay applied to the entire grid. Every cell loses `evaporation_rate` per step, clamped at zero. Trails that are not reinforced by agent traffic fade and disappear. The network prunes itself — weak branches evaporate, strong branches persist. This is the same decay mechanic from the Greenberg-Hastings model repurposed as a forgetting mechanism. Decay in excitable media creates refractory periods. Decay in the mold network creates selection pressure. Same operation, different context, different emergent meaning.

The ratio of `deposit_amount` to `evaporation_rate` determines the steady-state intensity of a trail maintained by a single agent. If an agent deposits 5 and evaporation removes 1 per step, a cell visited every 5 steps hovers near equilibrium. A cell visited every 2 steps accumulates. A cell visited every 10 steps fades. The ratio is a survival threshold — trails above it grow, trails below it die. The grid performs a distributed computation that filters signal from noise, keeping only the paths that carry enough traffic to justify their existence.

## From Two States to a Spectrum

Binary automata are switches. Multi-state automata are dials. The transition from CA_4 to CA_5 is the transition from digital logic to analog-like dynamics on a discrete substrate. Decay introduces temporal memory: the current state whispers what the previous state was. Cyclic rules introduce perpetual motion: no absorbing state, no equilibrium, only rotation. Agent-based models like the mold network introduce heterogeneous dynamics: the grid is passive substrate, the agents are active participants, and the multi-state encoding is the shared language between them.

The state count k is a resolution parameter. At k = 2, the automaton is a binary machine. At k = 256, it approximates a continuous field with 8-bit precision. The rules do not change in kind — they still map current state plus neighborhood to next state. But the behavioral repertoire expands with k. Thin refractory periods become wide recovery zones. Sharp wavefronts become smooth gradients. Binary patterns become textured fields. The information capacity of each cell scales with log2(k) bits, and the automaton's expressive range scales with it.

CA_6 extends the neighborhood. Where CA_5 widens the state space, CA_6 widens the spatial reach — Moore neighborhoods that extend beyond the immediate eight, pulling information from sixteen or twenty-four cells. State depth and spatial reach are orthogonal axes of generalization. CA_5 stretches one. CA_6 stretches the other. Together they define the parameter space in which complex automata live.

## Possible Artifacts

**cyclic_spiral_display** — A grid running the cyclic automaton with k = 16 and hue-mapped states. The spiral arms rotate visibly, color cycling through the full state range. A slider adjusts k in real time, demonstrating how the number of states controls spiral tightness and rotation speed. Contrasts directly with the decay trails of the petri dish: cycling versus fading, closed orbits versus absorbing states. The visual difference between the two dynamics is the argument for why state topology matters.

**excitable_wave_launcher** — An interactive surface where the learner taps to inject an excited cell into a resting field. The Greenberg-Hastings rule propagates the excitation as an expanding ring. Tapping a second point while the first ring is still refractory creates interference patterns — colliding wavefronts annihilate where they meet. A broken-wavefront mode seeds a curved initial excitation that automatically curls into a self-sustaining spiral. Demonstrates refractory blocking, wavefront collision, and spiral genesis from a single rule set.

**trail_strength_histogram** — Overlays the mold network with a live histogram showing the distribution of cell states across the grid. As the network self-organizes, the histogram shifts from a uniform distribution (random initialization) to a bimodal distribution (many zeros from evaporated cells, a peak at high values from reinforced trails). Quantifies the transition from disorder to structure and makes the pruning process legible as a statistical shift rather than a purely visual one.
