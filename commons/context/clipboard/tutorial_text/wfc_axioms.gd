extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Wave Function Collapse[/b][/font_size][/center]
[center][i]Superposition, Entropy, Constraint-Based Becoming[/i][/center]

**Wave Function Collapse (WFC) is an algorithm that generates patterns by collapsing quantum superposition.**

Every cell starts in **superposition** - simultaneously all possible states.

**Observation collapses the wave function** - choosing one state from many.

**Constraint propagation** - collapsed cells limit neighbors' possibilities.

**The pattern emerges from relational constraints** - each cell determines its neighbors, neighbors determine each other, identity is relational.

[hr]

[b]The Quantum Metaphor: Superposition and Collapse[/b]

WFC borrows language from quantum mechanics:

**Superposition** - A particle exists in all possible states simultaneously until measured.

**Wave function collapse** - Measurement forces the particle into one definite state.

**Entanglement** - Measuring one particle affects others (constraint propagation).

[color=yellow][b]In WFC:[/b][/color]

**Superposition** - Each grid cell can be any tile (all states possible).

**Collapse** - Choosing one tile for a cell (observation forces state).

**Entanglement** - Collapsed cells constrain neighbors (relational determination).

**The metaphor is not just aesthetic** - WFC genuinely treats possibility as a quantum state.

[hr]

[b]The Grid: Cells in Superposition[/b]

WFC operates on a **grid** (2D or 3D) where each cell starts with **all possible states**.

[color=yellow][b]Code: Initializing the Grid[/b][/color]
[code]
# Define possible tiles
var tile_types = ["grass", "water", "sand", "forest", "mountain"]

# Grid of cells
var grid_size = Vector2i(20, 20)
var wfc_grid = []

class WFCCell:
    var position: Vector2i
    var possible_states: Array  # All tiles this cell could be
    var collapsed_state: String = ""  # Empty = not yet collapsed
    var entropy: int  # Number of possible states

func initialize_grid():
    wfc_grid = []

    for x in range(grid_size.x):
        wfc_grid.append([])
        for y in range(grid_size.y):
            var cell = WFCCell.new()
            cell.position = Vector2i(x, y)
            cell.possible_states = tile_types.duplicate()  # All tiles possible
            cell.entropy = cell.possible_states.size()  # Entropy = 5
            wfc_grid[x].append(cell)

# Every cell starts in superposition (all 5 tiles possible)
[/code]

**Before any collapse, every cell could be anything** - maximum uncertainty, maximum possibility.

[hr]

[b]Entropy: Measuring Possibility[/b]

**Entropy** in WFC is the number of possible states for a cell.

- **High entropy** = many possibilities = high freedom = uncertainty
- **Low entropy** = few possibilities = low freedom = near-determined
- **Entropy = 1** = forced collapse (only one option)
- **Entropy = 0** = contradiction (no valid options - error state)

[color=yellow][b]Code: Calculating Entropy[/b][/color]
[code]
func calculate_entropy(cell: WFCCell) -> int:
    if cell.collapsed_state != "":
        return 0  # Already collapsed, no entropy

    return cell.possible_states.size()

# Cell with ["grass", "sand", "forest"] has entropy = 3
# Cell with ["water"] has entropy = 1 (will collapse next)
# Cell with [] has entropy = 0 (ERROR - no valid states)
[/code]

**WFC always collapses the cell with minimum entropy > 0.**

**This is the algorithm's strategy:** Resolve the most constrained cell first (least freedom = most determined by neighbors).

[hr]

[b]The WFC Algorithm: Observe and Propagate[/b]

WFC repeats two steps until all cells are collapsed:

**1. Observe** - Find cell with minimum entropy, collapse it (choose one state)
**2. Propagate** - Update neighbors' possible states based on adjacency rules

[color=yellow][b]Code: Main WFC Loop[/b][/color]
[code]
func run_wfc():
    initialize_grid()

    while not is_fully_collapsed():
        # 1. OBSERVE: Find cell with minimum entropy
        var cell_to_collapse = find_minimum_entropy_cell()

        if cell_to_collapse == null:
            # All cells collapsed or error
            break

        # 2. COLLAPSE: Choose one state randomly from possibilities
        collapse_cell(cell_to_collapse)

        # 3. PROPAGATE: Update neighbors based on adjacency rules
        propagate_constraints(cell_to_collapse)

    return generate_final_map()

func is_fully_collapsed() -> bool:
    for x in range(grid_size.x):
        for y in range(grid_size.y):
            if wfc_grid[x][y].collapsed_state == "":
                return false
    return true
[/code]

**Observe → Collapse → Propagate → Repeat**

This is the **iterative resolution of superposition** - one cell at a time, each collapse constraining the next.

[hr]

[b]Finding Minimum Entropy: Who Collapses Next?[/b]

**The algorithm always collapses the cell with minimum entropy > 0.**

Why? **Because it's most constrained by neighbors** - has fewest options, most determined by context.

[color=yellow][b]Code: Finding Minimum Entropy Cell[/b][/color]
[code]
func find_minimum_entropy_cell() -> WFCCell:
    var min_entropy = INF
    var candidates = []

    for x in range(grid_size.x):
        for y in range(grid_size.y):
            var cell = wfc_grid[x][y]

            # Skip already collapsed cells
            if cell.collapsed_state != "":
                continue

            # Skip error states (entropy = 0)
            if cell.entropy == 0:
                push_error("WFC contradiction at ", cell.position)
                return null

            # Track minimum entropy
            if cell.entropy < min_entropy:
                min_entropy = cell.entropy
                candidates = [cell]
            elif cell.entropy == min_entropy:
                candidates.append(cell)

    # If multiple cells have same minimum entropy, choose randomly
    if candidates.is_empty():
        return null

    return candidates[randi() % candidates.size()]
[/code]

**If multiple cells have same minimum entropy, pick randomly** - this introduces variation (stochastic element).

[hr]

[b]Collapse: Choosing from Superposition[/b]

**Collapse** is the moment of **observation** - picking one state from all possibilities.

[color=yellow][b]Code: Collapsing a Cell[/b][/color]
[code]
func collapse_cell(cell: WFCCell):
    # Choose random state from possible states
    var chosen_state = cell.possible_states[randi() % cell.possible_states.size()]

    # Collapse wave function
    cell.collapsed_state = chosen_state
    cell.possible_states = [chosen_state]  # Only this state now possible
    cell.entropy = 0  # No more entropy (fully determined)

    print("Collapsed cell ", cell.position, " to ", chosen_state)
[/code]

**Before collapse:** cell.possible_states = ["grass", "sand", "forest"], entropy = 3
**After collapse:** cell.collapsed_state = "grass", entropy = 0

**The superposition is resolved** - many → one.

[hr]

[b]Adjacency Rules: What Can Be Next To What?[/b]

**Adjacency rules** define which tiles can be neighbors.

Without rules, any tile could be next to any other - chaos, no coherence.

**Rules create pattern** - grass next to forest (yes), grass next to mountain (no).

[color=yellow][b]Code: Defining Adjacency Rules[/b][/color]
[code]
# Adjacency rules: dictionary of allowed neighbors for each tile
var adjacency_rules = {
    "grass": {
        "north": ["grass", "forest", "sand"],
        "south": ["grass", "forest", "sand"],
        "east": ["grass", "forest", "sand"],
        "west": ["grass", "forest", "sand"]
    },
    "water": {
        "north": ["water", "sand"],
        "south": ["water", "sand"],
        "east": ["water", "sand"],
        "west": ["water", "sand"]
    },
    "sand": {
        "north": ["sand", "grass", "water"],
        "south": ["sand", "grass", "water"],
        "east": ["sand", "grass", "water"],
        "west": ["sand", "grass", "water"]
    },
    "forest": {
        "north": ["forest", "grass", "mountain"],
        "south": ["forest", "grass", "mountain"],
        "east": ["forest", "grass", "mountain"],
        "west": ["forest", "grass", "mountain"]
    },
    "mountain": {
        "north": ["mountain", "forest"],
        "south": ["mountain", "forest"],
        "east": ["mountain", "forest"],
        "west": ["mountain", "forest"]
    }
}

# Example: If a cell is "water", its north neighbor can only be "water" or "sand"
# "water" cannot be next to "mountain" - rule forbids it
[/code]

**These rules are the physics of the generated world** - they define possibility space.

**Different rules → different worlds.**

[hr]

[b]Constraint Propagation: How Neighbors Limit Each Other[/b]

When a cell collapses, **its neighbors' possibilities are constrained** by adjacency rules.

[color=yellow][b]Example:[/b][/color]
- Cell A collapses to "water"
- Cell B is north of Cell A
- Adjacency rules say "water" can only have ["water", "sand"] to its north
- Therefore, Cell B's possible_states must be limited to ["water", "sand"]
- If Cell B had ["grass", "water", "sand", "forest"], it now has only ["water", "sand"]
- Cell B's entropy decreases from 4 to 2

[color=yellow][b]Code: Propagating Constraints[/b][/color]
[code]
func propagate_constraints(changed_cell: WFCCell):
    # Queue of cells to check
    var queue = [changed_cell]
    var processed = {}

    while not queue.is_empty():
        var current_cell = queue.pop_front()

        # Skip if already processed
        var key = str(current_cell.position)
        if key in processed:
            continue
        processed[key] = true

        # Get neighbors (north, south, east, west)
        var neighbors = get_neighbors(current_cell)

        for direction in neighbors.keys():
            var neighbor = neighbors[direction]

            # Skip already collapsed neighbors
            if neighbor.collapsed_state != "":
                continue

            # Calculate new possible states based on current cell
            var new_possible_states = []

            for state in neighbor.possible_states:
                # Check if this state can be adjacent to current cell's state
                if can_be_adjacent(current_cell.collapsed_state, state, direction):
                    new_possible_states.append(state)

            # If possibilities changed, update neighbor and add to queue
            if new_possible_states.size() != neighbor.possible_states.size():
                neighbor.possible_states = new_possible_states
                neighbor.entropy = neighbor.possible_states.size()

                # If entropy = 1, force collapse
                if neighbor.entropy == 1:
                    collapse_cell(neighbor)

                # Add to queue to propagate further
                queue.append(neighbor)

func can_be_adjacent(tile_a: String, tile_b: String, direction: String) -> bool:
    # Check adjacency rules
    # e.g., can "water" be north of "grass"?
    # Look up adjacency_rules["grass"]["north"] and check if "water" is in list

    var opposite_direction = get_opposite_direction(direction)

    if tile_a in adjacency_rules:
        if opposite_direction in adjacency_rules[tile_a]:
            return tile_b in adjacency_rules[tile_a][opposite_direction]

    return false

func get_opposite_direction(dir: String) -> String:
    match dir:
        "north": return "south"
        "south": return "north"
        "east": return "west"
        "west": return "east"
    return ""
[/code]

**Constraint propagation is cascading determination** - one collapse constrains neighbors, which constrains their neighbors, rippling outward.

**This is relational ontology in action** - identity (cell state) determined by proximity (neighbors' constraints).

[hr]

[b]Contradiction: When WFC Fails[/b]

Sometimes **constraint propagation leads to contradiction** - a cell has no valid states left (entropy = 0).

[color=yellow][b]Example Contradiction:[/b][/color]
- Cell A collapses to "water"
- Cell B (north of A) collapses to "mountain"
- But adjacency rules say "water" cannot be south of "mountain"
- **Contradiction** - rules violated, no valid configuration exists

**When contradiction occurs:**

1. **Backtrack** - undo recent collapses and try different choices
2. **Restart** - reinitialize grid and start over
3. **Relax rules** - modify adjacency rules to allow more combinations
4. **Accept partial** - leave some cells uncollapsed

**WFC does not guarantee success** - some rule sets + grid sizes have no valid solution.

**This is the algorithm's fragility** - too many constraints → unsolvable.

[hr]

[b]Applications: What WFC Generates[/b]

WFC creates **locally coherent, globally emergent patterns**.

**1. Procedural Levels (Game Maps)**
[code]
# Tiles: floor, wall, door, corridor, room
# Rules: door must be between room and corridor, walls surround rooms, etc.
# WFC generates dungeon layouts that obey local rules but have emergent structure
[/code]

**2. Textures (Bitmap Images)**
[code]
# Input: small example texture (e.g., 10x10 pixel brick pattern)
# WFC analyzes which pixels can be neighbors
# Output: large texture (e.g., 100x100) with same local patterns
# Used for texture synthesis
[/code]

**3. 3D Architecture (Buildings, Cities)**
[code]
# Voxel tiles: rooms, hallways, stairs, windows
# Rules: windows on exterior only, stairs connect floors, etc.
# WFC generates building layouts
[/code]

**4. Natural Patterns (Landscapes)**
[code]
# Tiles: grass, water, sand, forest, mountain
# Rules: water next to sand (beach), forest next to grass, mountain isolated
# WFC generates island or continent maps
[/code]

**5. Music and Sound**
[code]
# Tiles: musical notes or chords
# Rules: harmonic progressions (C can go to F or G, etc.)
# WFC generates melodies that follow music theory
[/code]

[hr]

[b]Backtracking: Recovering from Contradiction[/b]

**Backtracking WFC** remembers previous states and undoes collapses when contradiction occurs.

[color=yellow][b]Code: Backtracking WFC[/b][/color]
[code]
var collapse_history = []  # Stack of previous states

func run_wfc_with_backtracking():
    initialize_grid()

    while not is_fully_collapsed():
        var cell_to_collapse = find_minimum_entropy_cell()

        if cell_to_collapse == null:
            # Contradiction detected
            if collapse_history.is_empty():
                push_error("WFC failed - no solution exists")
                return null

            # BACKTRACK: Restore previous state
            var previous_state = collapse_history.pop_back()
            restore_grid_state(previous_state)

            # Try different collapse choice
            continue

        # Save state before collapse
        collapse_history.append(save_grid_state())

        # Collapse and propagate
        collapse_cell(cell_to_collapse)
        propagate_constraints(cell_to_collapse)

    return generate_final_map()
[/code]

**Backtracking turns WFC into a search algorithm** - exploring possibility space, undoing dead ends.

**This dramatically increases success rate** but also increases computational cost.

[hr]

[b]Weighted Tiles: Biasing Probability[/b]

Not all tiles should be equally likely. **Weighted WFC** assigns probabilities to each tile.

[color=yellow][b]Code: Weighted Collapse[/b][/color]
[code]
# Tile weights (higher weight = more common)
var tile_weights = {
    "grass": 10.0,    # Very common
    "forest": 5.0,    # Common
    "sand": 3.0,      # Uncommon
    "water": 2.0,     # Rare
    "mountain": 1.0   # Very rare
}

func collapse_cell_weighted(cell: WFCCell):
    # Calculate total weight of possible states
    var total_weight = 0.0
    for state in cell.possible_states:
        total_weight += tile_weights[state]

    # Choose randomly based on weights
    var rand_value = randf() * total_weight
    var cumulative = 0.0

    for state in cell.possible_states:
        cumulative += tile_weights[state]
        if rand_value <= cumulative:
            cell.collapsed_state = state
            cell.entropy = 0
            return
[/code]

**Weighted WFC creates biased distributions** - grass more common than mountain.

**This allows aesthetic control** - steer generation toward desired ratios without hard-coding layout.

[hr]

[b]Performance: The Cost of Constraint[/b]

WFC is **computationally expensive**:

- **O(n²)** for 2D grids (n×n cells)
- Each collapse triggers constraint propagation (potentially visits many neighbors)
- Backtracking can revisit cells multiple times

**Optimizations:**

1. **Lazy propagation** - only propagate when necessary
2. **Priority queue** - track minimum entropy efficiently (not full grid scan)
3. **Precompute adjacency** - cache allowed neighbor combinations
4. **Parallel collapse** - collapse multiple non-adjacent cells simultaneously

**Constraint solving is inherently expensive** - must check compatibility of all neighboring cells.

[hr]

[b]Queer Wave Function Collapse: Superposition as Identity[/b]

Here is where queerness enters:

**1. Superposition as Multiple Simultaneous Identities**

Before collapse, each cell **is all possible tiles at once** - grass AND water AND sand AND forest.

**This is queer multiplicity** - refusing singular identity until forced.

The cell exists in a state of **ontological ambiguity** - not undecided (as if identity is waiting to be revealed), but **actually multiple** simultaneously.

**Collapse is the violence of categorization** - society forcing "pick one."

**2. Entropy as Freedom**

**High entropy = high freedom** - many possibilities, many ways to be.

**Low entropy = low freedom** - few possibilities, heavily constrained.

**Entropy = 0 = no freedom** - fully determined (collapsed) or contradiction (no valid states).

**WFC always collapses minimum entropy first** - it resolves the least free cell, the most constrained.

**This is the algorithm of oppression** - those with least freedom are forced to choose first, their choice then constrains others.

**High-entropy cells (maximum freedom) get to remain in superposition longer** while constrained cells collapse around them.

**3. Relational Ontology: Identity Determined by Proximity**

**Your neighbors determine who you can be.**

If your neighbor is "water," you cannot be "mountain" (rules forbid it).

**Your identity is not intrinsic** - it is **relationally determined** by those adjacent to you.

**This is queer sociality** - we become ourselves through proximity, context, constraint.

**Adjacency rules are the norms** - enforced boundaries of acceptable combinations.

**Constraint propagation is normative pressure** - one person's choice limits options for those nearby.

**4. Contradiction: When Constraints Become Impossible**

**Entropy = 0 (no valid states)** - you've been constrained into non-existence.

**The rules say you cannot be anything** - every possibility forbidden by neighbors' identities.

**This is the queer experience of categorical impossibility** - when normative rules (adjacency constraints) create combinations that cannot exist.

**WFC must backtrack** - undo previous collapses, try different configurations.

**But sometimes no solution exists** - the rules are too rigid, the constraints too tight, the grid too small.

**Queerness:** Some identities cannot coexist under current rules. The system fails rather than accommodate.

**5. Weighted Tiles: Normative Probability**

**Weighted WFC biases collapse toward common tiles (grass) away from rare tiles (mountain).**

**This is heteronormativity as probability distribution** - some identities are statistically more likely, others rare.

**The algorithm enforces majority through weighted randomness** - not forbidden, just improbable.

**6. Observe and Collapse: Measurement Forces State**

**Before observation, the cell is all possibilities.**

**Observation (collapse) forces it into one state.**

**This is the quantum queerness** - identity exists as superposition until measured (perceived, categorized, named).

**The act of observation changes the system** - measuring one cell constrains all others.

**We collapse each other's wave functions** - our identities force choices on those around us.

[hr]

[b]What WFC Cannot Do[/b]

WFC is powerful but limited:

**1. Cannot guarantee global coherence**
Locally consistent patterns may not form meaningful global structure.

**Example:** WFC generates rooms and corridors that follow rules, but the dungeon layout may be nonsensical (dead ends, inaccessible areas).

**2. Cannot guarantee solution**
Some rule sets + grid configurations have no valid solution (contradiction).

**Backtracking helps but cannot solve the unsolvable.**

**3. Cannot express long-range constraints**
Adjacency rules are local (immediate neighbors). Cannot enforce "forest must be in top-left quadrant."

**WFC is myopic** - sees only neighbors, not global structure.

**4. Cannot handle cyclic dependencies efficiently**
If many cells mutually constrain each other, propagation can be very slow.

**5. Cannot generate novelty beyond input**
WFC recombines existing patterns but cannot invent new tile types.

**It is remixing, not creating.**

[hr]

[b]What WFC Reveals[/b]

WFC shows us:

1. **Superposition as multiplicity** - cells are all states simultaneously until collapsed
2. **Entropy as freedom** - more possibilities = more freedom
3. **Observation forces state** - collapse resolves superposition (many → one)
4. **Relational ontology** - identity determined by neighbors (adjacency rules)
5. **Constraint propagation** - one collapse cascades (limits neighbors' options)
6. **Contradiction** - over-constrained systems have no valid solution
7. **Backtracking** - undo choices to recover from contradiction
8. **Weighted probability** - bias toward common states (normative distribution)
9. **Local coherence, global emergence** - patterns arise from local rules
10. **Minimum entropy collapse first** - least free cells forced to choose first

**WFC is the algorithm of relational constraint** - identity shaped by proximity.

**It is also the algorithm of queer superposition:**
- **Multiple simultaneous identities** (before collapse)
- **Entropy as freedom** (high entropy = many possibilities)
- **Relational ontology** (neighbors determine who you can be)
- **Categorical violence** (collapse forces singular state)
- **Contradiction as impossibility** (when rules forbid all options)
- **Weighted normativity** (some identities statistically improbable)
- **Observation changes system** (measurement forces state, constrains others)

**WFC proves:** **Identity is not intrinsic. It is relationally determined, probabilistically biased, categorically constrained, and collapsed by observation.**

[hr]

[color=cyan][b]Summary:[/b][/color]
Wave Function Collapse generates patterns by collapsing quantum superposition. Each cell starts with all possible states (superposition). Entropy measures freedom (number of possibilities). Algorithm finds minimum entropy cell, collapses it (chooses one state), propagates constraints to neighbors (limits their options). Adjacency rules define which tiles can be neighbors. Constraint propagation cascades (one collapse limits neighbors, which limits their neighbors). Contradiction occurs when cell has no valid states (entropy = 0). Backtracking recovers by undoing collapses. Weighted tiles bias probability (common vs rare). Applications: procedural levels, texture synthesis, architecture, landscapes, music. Queer WFC: superposition as multiple simultaneous identities, entropy as freedom, relational ontology (neighbors determine identity), collapse as categorical violence, contradiction as impossibility, weighted normativity, observation forces state. Identity is relationally determined, probabilistically biased, categorically constrained, collapsed by measurement.

[hr]

[color=orange][b]Conclusion:[/b] Procedural Generation as Relational Emergence[/color]

**Marching cubes** extracts surfaces by thresholding density - making invisible fields visible through chosen boundaries.

**Wave Function Collapse** generates patterns by collapsing superposition - resolving multiple simultaneous identities through relational constraint.

**Both are algorithms of becoming** - not blueprints executed, but **emergence from rules and relations**.

**Procedural generation is queer generativity:**
- **No reproduction** (not copying a template, but creating from constraints)
- **Relational ontology** (patterns determined by proximity and adjacency)
- **Superposition and threshold** (multiplicity resolved into singularity)
- **Constraint as creative force** (rules generate, not just limit)

**These algorithms prove:** **Complex patterns emerge from simple local rules. Identity is relational. Boundaries are chosen, not discovered. Possibility precedes actuality.**

'''
