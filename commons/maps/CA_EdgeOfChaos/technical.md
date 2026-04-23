# Rules sort into four behavioral classes and a narrow critical band between order and chaos turns out to be the only place where computation happens

CA_10 introduced the agent. A single ant walked a grid, flipping cells, building a highway nobody encoded. Two rules, ten thousand chaotic steps, then sudden periodicity. The highway was a Class II attractor — periodic, self-sustaining, predictable once locked in. The transient before it was something else: irregular, incompressible, resistant to shortcut. The same system exhibited two qualitatively different behaviors in sequence.

CA_12 names this distinction. Every cellular automaton, whether field-based or agent-based, whether 1D elementary or 3D volumetric, falls into one of four behavioral classes. Three are computationally dead. The fourth — balanced on the edge between frozen order and boiling chaos — is where all interesting computation lives. Wolfram classified the rules. Langton quantified the transition. This map makes the boundary visible.

## The Four Classes

Wolfram observed that all elementary cellular automata, regardless of rule number, produce output in one of four qualitative categories.

Class I: Fixed point. All cells converge to a uniform state. Start with any initial condition; after a few generations, every cell is identical. The system dies into homogeneity. Rule 0 and Rule 255 are trivial examples, but subtler rules also collapse — they just take longer.

Class II: Periodic. The system settles into stable oscillators or static structures. Cells form repeating patterns with a fixed cycle period. Langton's ant highway is Class II — period 104, extending indefinitely. Most of the 256 elementary rules are Class II.

Class III: Chaotic. Aperiodic, apparently random output. Statistical tests on the cell patterns yield values indistinguishable from a random process, though the system is deterministic. Rule 30 is canonical — its center column passes randomness tests and was used as a pseudorandom generator.

Class IV: Complex. Localized structures interact, propagate, and sometimes annihilate. Gliders and other persistent motifs emerge, collide, and produce new structures from collisions. Rule 110, proven Turing-complete, is canonical. Game of Life is a 2D Class IV system.

```gdscript
enum WolframClass { FIXED_POINT, PERIODIC, CHAOTIC, COMPLEX }

func classify_by_entropy(generations: Array[Array], window: int) -> WolframClass:
    var entropy_values: Array[float] = []
    for i in range(generations.size() - window, generations.size()):
        entropy_values.append(_shannon_entropy(generations[i]))
    var mean_entropy := _mean(entropy_values)
    var entropy_variance := _variance(entropy_values)

    if mean_entropy < 0.01:
        return WolframClass.FIXED_POINT
    if entropy_variance < 0.001 and mean_entropy < 0.5:
        return WolframClass.PERIODIC
    if entropy_variance < 0.001 and mean_entropy > 0.7:
        return WolframClass.CHAOTIC
    return WolframClass.COMPLEX
```

The classifier measures Shannon entropy over a sliding window of recent generations. Class I produces near-zero entropy — uniformity carries no information. Class II produces low, stable entropy — repeating patterns compress well. Class III produces high, stable entropy — no compressible structure. Class IV produces fluctuating entropy — information content varies as structures form and dissolve. The variance of entropy, not just its value, distinguishes complex from chaotic.

This classification is empirical, not algorithmic. No known procedure takes a rule table as input and outputs the Wolfram class without simulation. The classification problem is undecidable for the general case — a consequence of the halting problem. Determining whether a rule is Class IV requires running it and watching. Observation precedes theory.

## Langton's Lambda

Chris Langton introduced a single parameter that traces the transition between classes. Lambda is the fraction of entries in a rule's transition table that map to a non-quiescent state.

Consider an elementary CA with k=2 states and a neighborhood of 3 cells. The transition table has 8 entries. If state 0 is designated quiescent, lambda counts how many of the 8 entries produce non-zero output.

```gdscript
func compute_lambda(rule_table: Array[int], quiescent_state: int = 0) -> float:
    var non_quiescent: int = 0
    for output in rule_table:
        if output != quiescent_state:
            non_quiescent += 1
    return float(non_quiescent) / float(rule_table.size())
```

Lambda ranges from 0.0 to 1.0. At lambda = 0, every neighborhood maps to the quiescent state — Class I. At lambda = 1, no neighborhood produces quiescence — also Class I, the opposite fixed point. Between these extremes, the classes arrange themselves:

Low lambda (near 0.0 or 1.0): Class I. Activity dies.

Moderate lambda (0.1-0.3, or 0.7-0.9): Class II. Enough activity for oscillation, not enough to prevent settling.

High lambda (near 0.5): Class III. Maximum entropy, aperiodic behavior.

Critical lambda (the narrow band where III meets II): Class IV. Structures persist long enough to interact but the system never freezes or dissolves.

```gdscript
func generate_rule_at_lambda(target_lambda: float, table_size: int,
                              quiescent: int = 0, k: int = 2) -> Array[int]:
    var table: Array[int] = []
    var non_quiescent_count: int = roundi(target_lambda * table_size)
    # Fill with quiescent state
    for i in range(table_size):
        table.append(quiescent)
    # Randomly assign non-quiescent outputs
    var indices: Array[int] = []
    for i in range(table_size):
        indices.append(i)
    indices.shuffle()
    for i in range(non_quiescent_count):
        table[indices[i]] = randi_range(1, k - 1) if k > 2 else 1
    return table
```

The generator produces a random rule table at a specified lambda. Run many rules at each lambda value and plot behavior class. Lambda predicts class tendency, not class identity. But the trend is clear. The edge of chaos clusters at the critical lambda. This is not a precise phase boundary. It is a crossover region — broad enough to contain variation, narrow enough to separate qualitative regimes.

## The Ca_Screen Artifact

The `ca_screen` artifact from CA_1 returns as the visual substrate for classification. It renders elementary CA evolution as a 2D spacetime grid: cells horizontal, time flowing downward.

```gdscript
func display_classification(rule_number: int, width: int, generations: int) -> void:
    var grid: Array[int] = _initialize_random(width)
    var history: Array[Array] = [grid.duplicate()]
    for g in range(generations):
        grid = _step_elementary(grid, rule_number)
        history.append(grid.duplicate())
    _render_spacetime(history)
    var classification := classify_by_entropy(history, mini(generations, 50))
    _display_class_label(classification)
```

The learner sees the spacetime diagram and the classification label together. Rule 0 produces a blank screen — Class I. Rule 4 produces scattered static blocks — Class II. Rule 30 produces a fractal-edged cascade — Class III. Rule 110 produces interacting gliders on a periodic background — Class IV. The label names what the eyes already see. The classification is a vocabulary for visual intuition.

The screen accepts a rule number as parameter. No mathematical analysis is required — the four classes are distinguishable by sight. Triangular wedges are Class III. Repeating wallpaper is Class II. Moving particles on a background are Class IV. Blankness is Class I. The eye is a competent classifier. Lambda provides the quantitative framework underneath.

## Disease Spread as Class IV Dynamics

The `disease_spread_ca` artifact models an SIR epidemic on a 2D grid. Three states: susceptible, infected, recovered. A susceptible cell becomes infected based on its infected neighbors and a probability threshold. Infected cells recover after a fixed number of generations. Recovered cells are immune.

```gdscript
enum SIRState { SUSCEPTIBLE, INFECTED, RECOVERED }

const INFECTION_PROBABILITY: float = 0.3
const RECOVERY_TIME: int = 5

func disease_step(grid: Array, timers: Array, width: int, height: int) -> void:
    var next_grid: Array = grid.duplicate(true)
    var next_timers: Array = timers.duplicate(true)
    for y in range(height):
        for x in range(width):
            match grid[y][x]:
                SIRState.SUSCEPTIBLE:
                    var infected_neighbors := _count_state(
                        grid, x, y, width, height, SIRState.INFECTED)
                    var infection_chance := 1.0 - pow(
                        1.0 - INFECTION_PROBABILITY, infected_neighbors)
                    if randf() < infection_chance:
                        next_grid[y][x] = SIRState.INFECTED
                        next_timers[y][x] = RECOVERY_TIME
                SIRState.INFECTED:
                    next_timers[y][x] -= 1
                    if next_timers[y][x] <= 0:
                        next_grid[y][x] = SIRState.RECOVERED
    grid.assign(next_grid)
    timers.assign(next_timers)
```

The infection probability per neighbor is 0.3. But the chance of escaping infection from multiple neighbors compounds: `1 - (1 - 0.3)^n` where n is the infected neighbor count. One infected neighbor gives 30%. Two gives 51%. Four gives 76%. The nonlinearity means the wavefront accelerates as it thickens.

At low infection probability, the disease dies out — a few cells infect, recover, and the chain breaks. Class I: the all-recovered fixed point. At high probability, the disease sweeps uniformly in a single wave, leaving uniform recovery behind. Also Class I, reached through a different trajectory. At intermediate probability, the wavefront develops irregular edges. Holes appear. Secondary outbreaks ignite in pockets the first wave missed. The boundary between infected and recovered becomes a complex, evolving interface — not periodic, not random, but structured.

This intermediate regime is Class IV. The wavefront is a localized structure that propagates, interacts with the grid's geometry, and produces emergent patterns. The SIR model at criticality lives at the edge of chaos. Too little infection and the system freezes. Too much and it washes out. The narrow band between those extremes is where epidemiological complexity resides.

The epidemiological R0 — the basic reproduction number — maps directly onto lambda. R0 less than 1: the disease dies. Class I. R0 much greater than 1: the disease saturates. Also Class I. R0 near 1: the critical threshold where infection chains neither explode nor collapse. The wavefront sustains itself at the edge, branching and pruning in equal measure. R0 is lambda in biological clothing.

```gdscript
func estimate_r0(grid: Array, timers: Array, width: int, height: int,
                  sample_steps: int) -> float:
    var total_new_infections: int = 0
    var total_recoveries: int = 0
    for s in range(sample_steps):
        var prev_infected := _count_total_state(grid, width, height, SIRState.INFECTED)
        disease_step(grid, timers, width, height)
        var new_infected := _count_total_state(grid, width, height, SIRState.INFECTED)
        var new_recovered := _count_total_state(grid, width, height, SIRState.RECOVERED)
        total_new_infections += maxi(0, new_infected - prev_infected + (new_recovered - _prev_recovered))
        total_recoveries += new_recovered - _prev_recovered
        _prev_recovered = new_recovered
    if total_recoveries == 0:
        return 0.0
    return float(total_new_infections) / float(total_recoveries)
```

When this ratio hovers near 1.0, the system is at criticality. The learner watches R0 fluctuate as the wavefront evolves — a numerical readout of the edge of chaos in real time.

## Self-Organization at Criticality

The `self_organization_ca` artifact demonstrates spontaneous pattern formation without templates. Cells begin in random states. The rule is totalistic — next state depends on the sum of neighbor states, not their arrangement.

```gdscript
func self_organize_step(grid: Array, width: int, height: int,
                         birth_range: Vector2i, survive_range: Vector2i) -> void:
    var next: Array = grid.duplicate(true)
    for y in range(height):
        for x in range(width):
            var alive_count := _count_alive_neighbors(grid, x, y, width, height)
            if grid[y][x] == 0:
                if alive_count >= birth_range.x and alive_count <= birth_range.y:
                    next[y][x] = 1
            else:
                if alive_count < survive_range.x or alive_count > survive_range.y:
                    next[y][x] = 0
    grid.assign(next)
```

Birth and survival ranges control the dynamics. Wide survival ranges produce stable structures — Class II. Wide birth ranges produce explosive growth — Class III. The critical tuning requires balanced ranges where birth barely exceeds death. Cells organize into clusters, stripes, or labyrinthine patterns that persist without external input. The patterns emerge from dynamics at the critical threshold, not from the rules.

The birth/survival notation compresses to a familiar form. Game of Life is B3/S23 — birth with exactly 3 alive neighbors, survival with 2 or 3. Changing a single threshold shifts the class. B3/S12345678 (survive with any neighbors) produces immortal growth — Class III. B3/S0 (survive with zero neighbors, die otherwise) produces single-generation flashes — Class I.

The parameter space is small — two ranges, each from 0 to 8 — but the behavioral space it spans covers all four Wolfram classes. The self-organization artifact exposes this space directly. Each slider position is a different automaton. Most positions are boring. A few are extraordinary. Finding them is the exercise.

Self-organized criticality — the tendency of driven systems to naturally approach the critical state — suggests that the edge of chaos is not a fine-tuned miracle but an attractor in parameter space. Systems that persist tend to evolve toward criticality because criticality maximizes adaptability. Too ordered and the system cannot respond to perturbation. Too chaotic and structure cannot accumulate. The edge is where information storage and information processing coexist.

Per Bak's sandpile model formalized this: grains of sand added one at a time to a pile produce avalanches whose sizes follow a power-law distribution. No tuning required. The critical state is the system's natural resting point. At criticality, perturbations decay as power laws — most cause small ripples, a few cause cascading reorganization. The distribution of avalanche sizes has no characteristic scale. This scale-free behavior is the statistical signature of the edge of chaos.

## Volumetric Fog as Atmospheric Automaton

The `volumetric_fog_ca` applies CA rules to a 3D density field. Each voxel holds a fog density value. The update rule smooths density based on neighbor averages while injecting perturbation at boundaries.

```gdscript
func fog_step(density: Array, width: int, height: int, depth: int,
              diffusion: float, turbulence: float) -> void:
    var next: Array = density.duplicate(true)
    for z in range(depth):
        for y in range(height):
            for x in range(width):
                var neighbor_avg := _average_neighbors_3d(
                    density, x, y, z, width, height, depth)
                var current: float = density[z][y][x]
                # Diffuse toward neighbor average
                var diffused := lerpf(current, neighbor_avg, diffusion)
                # Add turbulence noise at boundary cells
                if _is_boundary(x, y, z, width, height, depth):
                    diffused += randf_range(-turbulence, turbulence)
                next[z][y][x] = clampf(diffused, 0.0, 1.0)
    density.assign(next)
```

High diffusion produces uniform fog — every voxel converges to the grid average. Class I. Low diffusion preserves initial noise — density remains frozen in its random state. Also Class I, but the static kind. The turbulence parameter at the boundary injects energy. Without it, diffusion drives toward equilibrium. With it, the boundary feeds disorder into the interior.

The interesting regime appears when diffusion and turbulence balance. Fog forms wisps — coherent structures that drift, merge, and dissipate. The wisps emerge from the tension between smoothing (order) and injection (chaos). The visual result resembles atmospheric fog because real fog occupies the same dynamical regime — thermal diffusion smooths gradients while convective turbulence disrupts them. The automaton captures qualitative atmospheric physics without solving the Navier-Stokes equations.

The `lerpf` call interpolates between the current density and the neighbor average. At `diffusion = 0.0`, the cell retains its current value. At `diffusion = 1.0`, the cell instantly adopts the neighbor average. Values between 0 and 1 control the rate of convergence. The `clampf` ensures density remains physical — no negative fog, no density exceeding the maximum.

The 3D neighbor average uses the same 26-neighbor Moore neighborhood from CA_9. Each voxel samples its surrounding cube and computes the arithmetic mean:

```gdscript
func _average_neighbors_3d(density: Array, cx: int, cy: int, cz: int,
                            w: int, h: int, d: int) -> float:
    var total: float = 0.0
    var count: int = 0
    for dz in range(-1, 2):
        for dy in range(-1, 2):
            for dx in range(-1, 2):
                if dx == 0 and dy == 0 and dz == 0:
                    continue
                var nx := clampi(cx + dx, 0, w - 1)
                var ny := clampi(cy + dy, 0, h - 1)
                var nz := clampi(cz + dz, 0, d - 1)
                total += density[nz][ny][nx]
                count += 1
    return total / float(count)
```

The `clampi` boundary handling reflects fog against the grid edges rather than wrapping. A voxel at the corner averages only 7 distinct positions; at a face, 17. The reduced neighbor count at boundaries amplifies local perturbations. Wisps nucleate at boundaries and propagate inward. The edge of the grid mirrors the edge of chaos — boundaries are where dynamics happen.

## The Edge as Organizing Principle

The edge of chaos is not a place. It is a dynamical regime. Systems at the edge exhibit maximal computational capacity — ordered enough to sustain structure, chaotic enough to propagate perturbations. Class I stores but cannot process. Class III processes but cannot store. Class IV does both.

This is the thesis the entire CA sequence has been building toward. Rule 110 in CA_1 demonstrated computation in a lookup table. CA_2 showed biological patterns from local chemistry. CA_5 produced Turing patterns via reaction-diffusion. CA_9 extended the grid into three dimensions. CA_10 replaced the field with a single agent. Each map added a dimension of complexity — more states, more neighbors, more spatial freedom, more update paradigms — but the underlying question was always the same: where does complexity come from?

The answer is not "from complex rules." Rule 110 uses 8 bits. Langton's ant uses 2 rules. Game of Life uses 2 thresholds. Complexity comes from the dynamical regime. The same rule structure that produces Class I at one parameter value produces Class IV at another. The edge of chaos is the parameter regime where computation happens. Move in either direction and computation dies — into crystalline repetition or thermal noise.

Langton's lambda quantifies this. Shannon entropy measures it. Visual inspection detects it. The four artifacts in this map present four views of one phenomenon: `ca_screen` in elementary automata, `disease_spread_ca` in epidemiology, `self_organization_ca` in pattern formation, `volumetric_fog_ca` in atmospheric physics. Four domains. One dynamical principle.

CA_11 takes the theory interactive. The learner defines rules, tunes parameters, and searches for the edge deliberately. Wireworld proves the endpoint: a four-state CA that builds logic gates, circuits, and computers. The edge of chaos is where automata become machines.

## Possible Artifacts

**lambda_slider** — An interactive parameter sweep from lambda = 0.0 to 1.0 with a continuous slider. At each position, a random rule table at the specified lambda runs for 200 generations on the `ca_screen`. The learner drags and watches the spacetime diagram transition through Classes I, II, IV, and III in sequence. A histogram below plots entropy per generation as a live signal. The slider makes the edge of chaos a tunable boundary — drag too far left and the system dies, too far right and it dissolves, and the narrow band where gliders appear is a physical sensation in the hand.

**class_sorter** — A gallery of pre-rendered spacetime diagrams from 20 rules, presented without labels. The learner drags each diagram into one of four class bins. The artifact scores accuracy and reveals the lambda value after classification. Misclassifications cluster at the Class II / Class IV boundary, demonstrating that the edge is genuinely ambiguous — not a failure of perception but a reflection of the continuous transition between regimes.

**criticality_tuner** — A 2D grid running a parameterized totalistic rule with adjustable birth and survival thresholds. Two sliders control the ranges. A secondary display plots population over time. At non-critical settings, population crashes to zero or saturates to maximum. At the critical setting, population fluctuates indefinitely — the signature of the edge. The learner tunes toward criticality by watching the population curve and develops intuition for balanced dynamics before knowing the mathematics.
