<<<ADA_BUNDLE>>>
sequence: cellularautomata
file: tutorial.md
maps: 9
skipped_passing: 0
created: 2026-04-24T04:45:00
only_failing: true
diff_mode: false
with_context: true
<<</ADA_BUNDLE>>>

<<<MAP: CA_Introduction>>>
# CA Introduction

A grid of cells. Each cell reads its neighbours. All update at once.

Build a 2D grid.

```gdscript
@export var size: Vector2i = Vector2i(32, 32)
var grid: Array = []

func initialise_random() -> void:
    grid.clear()
    for y in size.y:
        var row: Array = []
        for x in size.x:
            row.append(1 if randf() < 0.3 else 0)
        grid.append(row)
```

Each cell is 0 or 1. Random initialisation with 30% live density.

Count Moore neighbourhood.

```gdscript
func count_neighbours(x: int, y: int) -> int:
    var count: int = 0
    for dy in [-1, 0, 1]:
        for dx in [-1, 0, 1]:
            if dx == 0 and dy == 0: continue
            var nx: int = (x + dx + size.x) % size.x
            var ny: int = (y + dy + size.y) % size.y
            count += grid[ny][nx]
    return count
```

Eight neighbours, periodic boundaries. The wrap-around lets patterns flow across the edges.

Apply a rule.

```gdscript
func apply_rule(alive: bool, neighbours: int) -> bool:
    if alive:
        return neighbours == 2 or neighbours == 3
    return neighbours == 3
```

Conway's Game of Life. Live cells survive with 2 or 3 neighbours; dead cells revive with exactly 3.

Step the grid.

```gdscript
func step() -> void:
    var new_grid: Array = []
    for y in size.y:
        var row: Array = []
        for x in size.x:
            var alive: bool = grid[y][x] == 1
            var count: int = count_neighbours(x, y)
            row.append(1 if apply_rule(alive, count) else 0)
        new_grid.append(row)
    grid = new_grid
```

Build a new grid from the old. The two must be separate — updating in place would corrupt the neighbour counts.

Render as a texture.

```gdscript
func to_texture() -> ImageTexture:
    var image := Image.create(size.x, size.y, false, Image.FORMAT_L8)
    for y in size.y:
        for x in size.x:
            image.set_pixel(x, y, Color.WHITE if grid[y][x] else Color.BLACK)
    return ImageTexture.create_from_image(image)
```

Greyscale. One pixel per cell, sampled nearest-neighbour for a pixelated look.

Animate the steps.

```gdscript
@export var steps_per_second: float = 10.0

var time_since_step: float = 0.0

func _process(delta: float) -> void:
    time_since_step += delta
    if time_since_step >= 1.0 / steps_per_second:
        time_since_step = 0.0
        step()
        update_texture()
```

Ten steps per second. Fast enough to show evolution; slow enough to watch structures form.

Seed a glider.

```gdscript
func seed_glider(x: int, y: int) -> void:
    var pattern := [[0, 1, 0], [0, 0, 1], [1, 1, 1]]
    for dy in pattern.size():
        for dx in pattern[0].size():
            grid[(y + dy) % size.y][(x + dx) % size.x] = pattern[dy][dx]
```

A specific starting pattern. The glider walks across the grid at one cell per four generations.

You can now build a 2D grid, count neighbours, apply Conway's rule, step and render, animate updates, and seed specific patterns. CA_ElementaryRules extends into 1D automata.

<<<MAP: CA_ElementaryRules>>>
# CA Elementary Rules

One dimension. Two states. 256 possible rules.

Encode a rule as an 8-bit number.

```gdscript
func rule_bit(rule: int, pattern: int) -> int:
    return (rule >> pattern) & 1
```

The rule's 8 bits specify the outcome for each of the 8 possible three-cell patterns. Rule 30 is binary 00011110.

Apply a rule to one row.

```gdscript
func step_row(row: Array, rule: int) -> Array:
    var new_row: Array = []
    var n: int = row.size()
    for i in n:
        var left: int = row[(i - 1 + n) % n]
        var centre: int = row[i]
        var right: int = row[(i + 1) % n]
        var pattern: int = left * 4 + centre * 2 + right
        new_row.append(rule_bit(rule, pattern))
    return new_row
```

Left, centre, right form a three-bit index. The rule's bit at that index is the new cell's state.

Generate a full 2D pattern.

```gdscript
func generate_rule_pattern(rule: int, width: int, generations: int) -> Array:
    var first: Array = []
    for _i in width: first.append(0)
    first[width / 2] = 1  # single seed in the middle
    var pattern: Array = [first]
    for g in range(1, generations):
        pattern.append(step_row(pattern[g - 1], rule))
    return pattern
```

Start with a single live cell. Each generation adds a row below the previous.

Render as an image.

```gdscript
func pattern_to_texture(pattern: Array) -> ImageTexture:
    var width: int = pattern[0].size()
    var height: int = pattern.size()
    var image := Image.create(width, height, false, Image.FORMAT_L8)
    for y in height:
        for x in width:
            image.set_pixel(x, y, Color.WHITE if pattern[y][x] else Color.BLACK)
    return ImageTexture.create_from_image(image)
```

One row per generation, stacked top-to-bottom. Time runs downward.

Classify a rule.

```gdscript
func classify_rule(rule: int, width: int = 101, generations: int = 200) -> String:
    var pattern := generate_rule_pattern(rule, width, generations)
    var final_density: float = 0.0
    for cell in pattern[generations - 1]:
        final_density += cell
    final_density /= width
    if final_density < 0.01: return "Class I (dies)"
    if is_periodic(pattern): return "Class II (periodic)"
    if appears_random(pattern): return "Class III (chaotic)"
    return "Class IV (complex)"
```

Wolfram's four classes. Classification is heuristic; the boundaries aren't sharp.

Render Rule 30 and Rule 110.

```gdscript
func display_famous_rules() -> void:
    render_at_position(generate_rule_pattern(30, 101, 200), Vector3(-2, 0, 0))
    render_at_position(generate_rule_pattern(110, 101, 200), Vector3(2, 0, 0))
```

Rule 30 produces chaos from order. Rule 110 supports moving localised structures — Turing complete.

Build the 256-rule gallery.

```gdscript
func build_gallery() -> void:
    for rule in 256:
        var pattern := generate_rule_pattern(rule, 33, 60)
        var texture := pattern_to_texture(pattern)
        var position := Vector3((rule % 16) * 0.4, 0, (rule / 16) * 0.4)
        spawn_rule_tile(rule, texture, position)
```

16×16 grid of small pattern tiles. Walk past and compare.

You can now encode a rule as 8 bits, apply it to a 1D array, generate a 2D pattern, render it, classify it, and display the gallery of 256 rules. CA_GameOfLife extends into Conway's 2D world.

<<<MAP: CA_GameOfLife>>>
# CA Game of Life

Birth, survival, death. Three rules produce infinite variety.

Implement the life-cycle rule.

```gdscript
func game_of_life_rule(alive: bool, neighbours: int) -> bool:
    if alive:
        return neighbours in [2, 3]  # survival
    return neighbours == 3  # birth
```

Two survival counts, one birth count. Every other count produces death.

Seed a glider.

```gdscript
const GLIDER := [
    [0, 1, 0],
    [0, 0, 1],
    [1, 1, 1],
]

func place_pattern(pattern: Array, x: int, y: int) -> void:
    for dy in pattern.size():
        for dx in pattern[0].size():
            var nx: int = (x + dx) % size.x
            var ny: int = (y + dy) % size.y
            grid[ny][nx] = pattern[dy][dx]
```

The glider walks diagonally. Four generations bring it back to the same shape, displaced by one cell.

Seed a glider gun.

```gdscript
const GOSPER_GLIDER_GUN := [
    # 36-wide, 9-tall pattern
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    # ... remaining rows
]
```

A structure that emits a new glider every 30 generations. Proves Conway's Life supports sustained activity.

Count the population.

```gdscript
func population() -> int:
    var count: int = 0
    for row in grid:
        for cell in row:
            if cell == 1: count += 1
    return count
```

Total live cells. Oscillators have periodic populations; gliders have constant populations.

Detect still lifes.

```gdscript
func is_still_life() -> bool:
    var next := step_to(grid.duplicate(true))
    return grids_equal(grid, next)
```

A configuration that doesn't change. Classic examples: block, beehive, loaf, boat.

Detect oscillators.

```gdscript
func is_oscillator(period: int) -> bool:
    var snapshot: Array = []
    for row in grid: snapshot.append(row.duplicate())
    for _i in period:
        step()
    return grids_equal(grid, snapshot)
```

Test whether the grid returns to its starting state after `period` steps. Period 2 catches blinkers; period 3 catches pulsars.

Render a life-and-death visualization.

```gdscript
func render_life_colored() -> void:
    for y in size.y:
        for x in size.x:
            var cell := grid[y][x]
            var age := cell_age[y][x]
            var color := Color.WHITE.lerp(Color.YELLOW, min(age / 20.0, 1.0)) if cell else Color.BLACK
            paint_cell(x, y, color)
```

Newly-born cells are white; older survivors fade toward yellow. The pattern's history becomes visible.

You can now implement Conway's rule, place standard patterns (glider, glider gun), count the population, detect still lifes and oscillators, and render the grid with age-colouring. CA_BeyondBinary extends into multi-state and hex grids.

<<<MAP: CA_BeyondBinary>>>
# CA Beyond Binary

Totalistic rules. Hex grids. Multi-state cells.

Totalistic rule (counts only).

```gdscript
func totalistic_rule(self_state: int, neighbour_sum: int, rule_table: Array) -> int:
    var index: int = self_state * (MAX_NEIGHBOURS + 1) + neighbour_sum
    return rule_table[index] if index < rule_table.size() else 0
```

The rule depends on the sum of neighbour states, not their arrangement. Table size: (states) × (max_sum + 1).

Generate a random totalistic rule.

```gdscript
func random_totalistic_rule(states: int, neighbours: int) -> Array:
    var table_size: int = states * (states * neighbours + 1)
    var rule: Array = []
    for _i in table_size:
        rule.append(randi() % states)
    return rule
```

Random entries from 0 to states-1. Most random rules produce boring chaos; a few produce interesting structure.

Hex grid cell neighbours.

```gdscript
func hex_neighbours(x: int, y: int) -> Array:
    var odd: bool = y % 2 == 1
    var offsets: Array = [
        Vector2i(-1, 0), Vector2i(1, 0),
        Vector2i(0, -1), Vector2i(0, 1),
    ]
    if odd:
        offsets.append(Vector2i(1, -1)); offsets.append(Vector2i(1, 1))
    else:
        offsets.append(Vector2i(-1, -1)); offsets.append(Vector2i(-1, 1))
    var result: Array = []
    for off in offsets:
        result.append(Vector2i((x + off.x + size.x) % size.x, (y + off.y + size.y) % size.y))
    return result
```

Six neighbours on a hex grid. Offset parity depends on whether the row is even or odd (offset-coordinate layout).

Count hex neighbours.

```gdscript
func count_hex_neighbours(x: int, y: int) -> int:
    var count: int = 0
    for nb in hex_neighbours(x, y):
        count += grid[nb.y][nb.x]
    return count
```

Same pattern as square grids; different coordinate lookup.

VR hex grid display.

```gdscript
func world_position_for_hex(x: int, y: int, spacing: float = 1.0) -> Vector3:
    var odd_offset: float = 0.5 if y % 2 == 1 else 0.0
    return Vector3((x + odd_offset) * spacing, 0, y * spacing * sqrt(3) / 2)
```

Hex cells tile with a staggered offset. The world positions produce the characteristic honeycomb pattern.

Multi-state cell.

```gdscript
func multi_state_rule(self_state: int, neighbours: Array) -> int:
    var sum_by_state: Dictionary = {}
    for n in neighbours:
        sum_by_state[n] = sum_by_state.get(n, 0) + 1
    var dominant_state: int = 0
    var dominant_count: int = 0
    for state in sum_by_state:
        if sum_by_state[state] > dominant_count:
            dominant_count = sum_by_state[state]; dominant_state = state
    return dominant_state if dominant_count > 2 else self_state
```

Cells take on the dominant neighbour state. Produces smoothing / blob behaviour; resembles Turing patterns.

Render cells by state.

```gdscript
const STATE_COLORS := [Color.BLACK, Color.BLUE, Color.GREEN, Color.RED, Color.YELLOW]

func paint_cell_by_state(x: int, y: int, state: int) -> void:
    get_cell(x, y).material_override.albedo_color = STATE_COLORS[state]
```

Each state maps to a colour. The grid becomes a multi-colour mosaic that evolves over time.

You can now build totalistic rules, hex-neighbour lookup, random rule generation, multi-state cells, and colour-coded rendering. CA_ExpandingSpace extends the neighbourhood reach.

<<<MAP: CA_ExpandingSpace>>>
# CA Expanding Space

The neighbourhood grows. More reach, different structure.

Variable-radius neighbourhood.

```gdscript
@export var radius: int = 1

func count_in_radius(x: int, y: int, r: int) -> int:
    var count: int = 0
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            if dx == 0 and dy == 0: continue
            var nx: int = (x + dx + size.x) % size.x
            var ny: int = (y + dy + size.y) % size.y
            count += grid[ny][nx]
    return count
```

Moore neighbourhood at arbitrary radius. Radius 1 gives 8 neighbours; radius 2 gives 24.

Weighted neighbourhood.

```gdscript
func weighted_neighbourhood(x: int, y: int, weights: Array) -> float:
    var total: float = 0.0
    var r: int = (weights.size() - 1) / 2
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            if dx == 0 and dy == 0: continue
            var w: float = weights[dy + r][dx + r]
            var nx: int = (x + dx + size.x) % size.x
            var ny: int = (y + dy + size.y) % size.y
            total += w * grid[ny][nx]
    return total
```

Each neighbour contributes its weight times its state. Equivalent to a convolution.

Smoothing kernel.

```gdscript
const SMOOTH_KERNEL := [
    [1, 2, 1],
    [2, 4, 2],
    [1, 2, 1],
]
```

Gaussian-like. Heavier weight on closer neighbours.

Grow a 3D tree from a cellular rule.

```gdscript
class_name CAGrowthTree extends Node3D

var occupied: Dictionary = {}  # Vector3i -> int

func grow_step(radius: int, threshold: int) -> void:
    var new_cells: Dictionary = {}
    for cell in occupied:
        for dx in range(-radius, radius + 1):
            for dy in range(-radius, radius + 1):
                for dz in range(-radius, radius + 1):
                    if dx == 0 and dy == 0 and dz == 0: continue
                    var candidate: Vector3i = cell + Vector3i(dx, dy, dz)
                    if candidate in occupied: continue
                    var count: int = count_occupied_neighbours(candidate, radius)
                    if count >= threshold:
                        new_cells[candidate] = 1
    for c in new_cells:
        occupied[c] = 1
```

Cells activate when enough nearby cells are already active. Produces fractal branching structures.

Spawn the tree.

```gdscript
func spawn_visual_cells() -> void:
    for cell in occupied:
        var mesh := MeshInstance3D.new()
        mesh.mesh = BoxMesh.new()
        mesh.scale = Vector3(0.2, 0.2, 0.2)
        mesh.position = Vector3(cell) * 0.3
        add_child(mesh)
```

Each occupied cell is a small cube. The tree emerges as an accumulation of cubes.

Crossway interference.

```gdscript
func crossway_step(zone_a: Array, zone_b: Array) -> void:
    for y in size.y:
        for x in size.x:
            var in_a: bool = Vector2i(x, y) in zone_a
            var in_b: bool = Vector2i(x, y) in zone_b
            var rule: Callable = rule_a if in_a else (rule_b if in_b else rule_default)
            grid[y][x] = rule.call(x, y)
```

Different regions use different rules. Overlap produces interference that neither region produces alone.

You can now implement variable-radius neighbourhoods, weighted convolutions, 3D CA tree growth, and cross-zone rule interference. CA_SoftRules extends into stochastic rules.

<<<MAP: CA_SoftRules>>>
# CA Soft Rules

Stochastic. Rules fire probabilistically rather than deterministically.

Stochastic rule application.

```gdscript
@export var fire_probability: float = 0.8

func stochastic_rule(alive: bool, neighbours: int) -> bool:
    if randf() > fire_probability:
        return alive  # rule didn't fire; state unchanged
    return standard_rule(alive, neighbours)
```

With probability fire_probability, apply the standard rule. Otherwise, keep the current state.

Noise-modulated Rule 30.

```gdscript
func soft_rule_30(left: int, centre: int, right: int) -> int:
    if randf() > 0.8:
        return centre  # no change
    var pattern: int = left * 4 + centre * 2 + right
    return rule_bit(30, pattern)
```

Rule 30 with 20% chance of no-update per cell. The pattern fuzzes but retains Rule 30's characteristic triangles.

Apply gravity bias.

```gdscript
@export var gravity_bias: float = 0.1

func biased_rule(alive: bool, neighbours: int) -> bool:
    var new_state: bool = standard_rule(alive, neighbours)
    if randf() < gravity_bias:
        return true  # biased toward alive
    return new_state
```

Environmental bias pushes the system toward a preferred state. Models thermal or gravitational drift.

Measure rule stability.

```gdscript
func measure_drift(steps: int = 100) -> float:
    var changes: int = 0
    for _i in steps:
        var old_grid: Array = grid.duplicate(true)
        step()
        for y in size.y:
            for x in size.x:
                if old_grid[y][x] != grid[y][x]: changes += 1
    return float(changes) / (steps * size.x * size.y)
```

Fraction of cells that change per step on average. Low for Class I; high for Class III.

Anneal the probability.

```gdscript
var current_probability: float = 0.5

func anneal_step(target: float, rate: float) -> void:
    current_probability = lerp(current_probability, target, rate)
    fire_probability = current_probability
```

Gradually adjust the stochasticity. Simulated annealing — start noisy, end crisp.

Detect steady-state distribution.

```gdscript
func steady_state(history: Array, window: int = 50) -> Dictionary:
    var counts: Dictionary = {}
    for snapshot in history.slice(-window):
        for row in snapshot:
            for cell in row:
                counts[cell] = counts.get(cell, 0) + 1
    var total: int = counts.values().reduce(func(a, b): return a + b, 0)
    var distribution: Dictionary = {}
    for state in counts:
        distribution[state] = float(counts[state]) / total
    return distribution
```

Histogram of states over recent history. Stable if the distribution converges over time.

You can now build stochastic rules, apply noise and gravity biases, measure drift, anneal stochasticity, and detect steady-state distributions. CA_AgentsCircuits extends into Wireworld.

<<<MAP: CA_AgentsCircuits>>>
# CA Agents Circuits

Wireworld. Cells can be empty, electron head, electron tail, or conductor.

Define cell states.

```gdscript
enum Cell { EMPTY, CONDUCTOR, HEAD, TAIL }
```

Four states. Empty never changes; the other three cycle in specific ways.

Apply the Wireworld rule.

```gdscript
func wireworld_rule(current: int, neighbours: Array) -> int:
    match current:
        Cell.EMPTY: return Cell.EMPTY
        Cell.HEAD: return Cell.TAIL
        Cell.TAIL: return Cell.CONDUCTOR
        Cell.CONDUCTOR:
            var head_count: int = 0
            for n in neighbours:
                if n == Cell.HEAD: head_count += 1
            if head_count == 1 or head_count == 2:
                return Cell.HEAD
            return Cell.CONDUCTOR
    return current
```

HEAD decays to TAIL; TAIL to CONDUCTOR; CONDUCTOR ignites when exactly 1 or 2 neighbours are HEAD. This rule supports signal propagation and logic.

Draw a wire.

```gdscript
func draw_wire(start: Vector2i, end: Vector2i) -> void:
    var current := start
    while current != end:
        grid[current.y][current.x] = Cell.CONDUCTOR
        var diff := end - current
        if abs(diff.x) > abs(diff.y):
            current.x += sign(diff.x)
        else:
            current.y += sign(diff.y)
    grid[end.y][end.x] = Cell.CONDUCTOR
```

Bresenham-style wire drawing. The learner can paint conductors with a controller.

Inject a signal.

```gdscript
func inject_electron(position: Vector2i) -> void:
    grid[position.y][position.x] = Cell.HEAD
```

A single HEAD cell. The signal propagates along any connected conductor.

Build an AND gate.

```gdscript
const AND_GATE := [
    [C, C, C, C, C, C, C],
    [C, 0, 0, 0, 0, 0, C],
    [C, 0, 0, 0, 0, 0, C],
    [C, C, C, C, C, C, C],
]
```

Two input wires converge. When both carry signals, the output wire ignites. Single inputs stall.

Test the gate.

```gdscript
func test_gate(gate_pattern: Array, inputs: Dictionary) -> int:
    place_pattern(gate_pattern, 0, 0)
    for input_pos in inputs:
        if inputs[input_pos]:
            inject_electron(input_pos)
    for _i in 20:  # run for 20 generations
        step()
    return read_output()
```

Place the gate; inject signals; run; read the output. Boolean logic via cellular automata.

Build a clock.

```gdscript
const CLOCK_RING := [
    [0, C, C, C, 0],
    [C, 0, 0, 0, C],
    [C, 0, 0, 0, C],
    [C, 0, 0, 0, C],
    [0, C, C, C, 0],
]
```

A closed loop of conductors. A HEAD placed on the ring circulates forever, producing periodic pulses.

You can now implement Wireworld, draw wires, inject signals, build logic gates, and test them via simulation. CA_EdgeOfChaos extends into classification.

<<<MAP: CA_EdgeOfChaos>>>
# CA Edge of Chaos

Four classes. Class IV — the edge — supports computation.

Classify by lambda.

```gdscript
func compute_lambda(rule: Array) -> float:
    var nonzero: int = 0
    for entry in rule:
        if entry != 0: nonzero += 1
    return float(nonzero) / rule.size()
```

Langton's lambda — fraction of rule entries that produce non-zero outputs. Low lambda: Class I; high: Class III; intermediate: Class IV.

Classify by activity.

```gdscript
func classify_by_activity(pattern: Array) -> String:
    var final := pattern[-1]
    var second_last := pattern[-2]
    if is_all_zero(final): return "Class I"
    if final == second_last: return "Class II"
    if appears_random(final): return "Class III"
    return "Class IV"
```

Heuristic classification from the pattern's trajectory. Rough but useful.

Detect gliders.

```gdscript
func find_moving_structures(pattern: Array, window: int = 20) -> int:
    var movers: int = 0
    for t in range(window, pattern.size()):
        var earlier := pattern[t - window]
        var current := pattern[t]
        if shifted_equal(earlier, current, Vector2i(window, 0)):
            movers += 1
    return movers
```

Count translational symmetries over time. Gliders produce many; static patterns produce none.

Disease-spread model.

```gdscript
enum Health { SUSCEPTIBLE, INFECTED, RECOVERED }

func sir_rule(self_state: int, neighbours: Array) -> int:
    match self_state:
        Health.SUSCEPTIBLE:
            for n in neighbours:
                if n == Health.INFECTED and randf() < 0.3:
                    return Health.INFECTED
            return Health.SUSCEPTIBLE
        Health.INFECTED:
            if randf() < 0.1:
                return Health.RECOVERED
            return Health.INFECTED
        Health.RECOVERED:
            return Health.RECOVERED
    return self_state
```

SIR epidemiological model. Spreads from infected to susceptible; infected recover over time.

Self-organisation demo.

```gdscript
func majority_rule_step() -> void:
    var new_grid: Array = []
    for y in size.y:
        var row: Array = []
        for x in size.x:
            var sum: int = 0
            for dy in [-1, 0, 1]:
                for dx in [-1, 0, 1]:
                    sum += grid[(y + dy + size.y) % size.y][(x + dx + size.x) % size.x]
            row.append(1 if sum >= 5 else 0)
        new_grid.append(row)
    grid = new_grid
```

Each cell takes the majority of its 3×3 neighbourhood. Produces large blobs from noise.

Volumetric fog.

```gdscript
func build_fog_layer(size: Vector3i) -> Array:
    var fog: Array = []
    for z in size.z:
        fog.append([])
        for y in size.y:
            fog[z].append([])
            for x in size.x:
                fog[z][y].append(randf() < 0.3)
    return fog

func fog_step(fog: Array) -> Array:
    # 3D CA rule — Class IV-ish
    var new_fog: Array = fog.duplicate(true)
    # Apply rule to each cell based on 3D neighbourhood count
    return new_fog
```

3D Class IV automaton. Cloud-like drifting structure emerges from random initialisation.

You can now compute lambda, classify patterns by activity and by moving structures, run SIR disease spread, majority-rule self-organisation, and 3D volumetric fog. Chamber_CA closes the sequence with rule-systems in contact.

<<<MAP: Chamber_CA>>>
# Chamber CA

Catalyst fires bursts. Creature's hide is a Game of Life grid.

Build the cellular catalyst.

```gdscript
class_name CellularCatalyst extends Node3D

@export var burst_pattern: Array = [
    [0, 1, 0],
    [1, 1, 1],
    [0, 1, 0],
]

func fire(aim: Vector3) -> void:
    var projectile := CELL_PROJECTILE_SCENE.instantiate()
    projectile.pattern = burst_pattern
    projectile.global_position = global_position
    projectile.linear_velocity = aim * 10.0
    get_tree().root.add_child(projectile)
```

Each projectile carries a small seed pattern. On impact, the pattern stamps onto the creature's hide.

Build the lifeform walker.

```gdscript
class_name LifeformWalker extends CharacterBody3D

@export var hide_size: Vector2i = Vector2i(32, 32)

var hide_grid: Array

func _ready() -> void:
    hide_grid.clear()
    for y in hide_size.y:
        var row: Array = []
        for x in hide_size.x:
            row.append(1 if randf() < 0.2 else 0)
        hide_grid.append(row)
```

The creature's hide is a small Conway grid. Random initialisation at 20% density.

Step the hide.

```gdscript
@export var hide_step_rate: float = 4.0

var time_since_step: float = 0.0

func _process(delta: float) -> void:
    time_since_step += delta
    if time_since_step >= 1.0 / hide_step_rate:
        time_since_step = 0.0
        step_hide()
        update_hide_texture()
```

Four updates per second. The hide's texture visibly evolves on the creature's body.

Stamp a pattern onto the hide.

```gdscript
func stamp_pattern(pattern: Array, at: Vector2i) -> void:
    for dy in pattern.size():
        for dx in pattern[0].size():
            if pattern[dy][dx] == 1:
                var hx: int = (at.x + dx) % hide_size.x
                var hy: int = (at.y + dy) % hide_size.y
                hide_grid[hy][hx] = 1
```

Sets live cells at the impact location. The pattern seeds a new local perturbation in the hide.

Detect a projectile hit.

```gdscript
func _on_body_entered(body: Node) -> void:
    if body.has_meta("pattern"):
        var impact_uv: Vector2 = uv_of_contact(body.global_position)
        var cell: Vector2i = Vector2i(impact_uv * Vector2(hide_size))
        stamp_pattern(body.pattern, cell)
        body.queue_free()
```

Contact triggers a stamp. The projectile is consumed.

Track surviving gliders.

```gdscript
func count_gliders() -> int:
    var count: int = 0
    for y in hide_size.y:
        for x in hide_size.x:
            if is_glider_at(x, y): count += 1
    return count
```

A glider is a specific small pattern. Counting them measures how many perturbations survived.

You can now build a cellular catalyst, stamp patterns onto the lifeform_walker's hide, step the hide at a chosen rate, and count surviving gliders. The Cellular Automata sequence closes with rule-systems in mutual contact.
