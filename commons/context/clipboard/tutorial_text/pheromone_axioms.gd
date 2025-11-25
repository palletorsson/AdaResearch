extends Node

# Tutorial content file
# Edit using the Tutorial Text Editor plugin

var text = '''[center][font_size=28][b]Pheromone Trails[/b][/font_size][/center]
[center][i]Stigmergy and Indirect Coordination[/i][/center]

**Ants don't plan. They leave chemical trails.** Others follow. Paths emerge without central control.

**Stigmergy = coordination through environmental modification.**

[hr]

[b]What Are Pheromones?[/b]

**Chemical signals left in environment:**

- Ants deposit pheromones while walking
- Other ants detect and follow strong pheromone trails
- Pheromones evaporate over time
- Shortest paths get reinforced (more traffic = more pheromone)

**No ant knows the full path. Collective finds optimal route.**

[hr]

[b]Basic Pheromone Grid[/b]

**Store pheromone strength per tile:**

[color=yellow][b]Code: 2D Pheromone Map[/b][/color]
[code]
extends Node2D

var grid_size = Vector2i(100, 100)
var pheromone_grid = {}  # Dictionary: Vector2i → float

func _ready():
    # Initialize grid to zero
    for y in range(grid_size.y):
        for x in range(grid_size.x):
            pheromone_grid[Vector2i(x, y)] = 0.0

func deposit_pheromone(cell: Vector2i, amount: float):
    if pheromone_grid.has(cell):
        pheromone_grid[cell] += amount
        pheromone_grid[cell] = clamp(pheromone_grid[cell], 0.0, 10.0)

func get_pheromone(cell: Vector2i) -> float:
    return pheromone_grid.get(cell, 0.0)

func _process(delta):
    evaporate_pheromones(delta)

func evaporate_pheromones(delta: float):
    var evaporation_rate = 0.5  # Units per second

    for cell in pheromone_grid:
        pheromone_grid[cell] -= evaporation_rate * delta
        pheromone_grid[cell] = max(pheromone_grid[cell], 0.0)

# Result: Grid stores pheromone values, decays over time
[/code]

[hr]

[b]Ant Agent (Follows Pheromones)[/b]

**Individual ant behavior:**

[color=yellow][b]Code: Pheromone-Following Ant[/b][/color]
[code]
extends CharacterBody2D

var current_cell: Vector2i
var pheromone_map: Node2D  # Reference to pheromone grid
var carrying_food = false

func _physics_process(delta):
    if carrying_food:
        move_toward_nest()
    else:
        move_toward_food()

    # Deposit pheromone at current cell
    current_cell = Vector2i(int(global_position.x / 10), int(global_position.y / 10))
    pheromone_map.deposit_pheromone(current_cell, 1.0)

func move_toward_food():
    # If not carrying food, follow food pheromone trail
    var neighbors = get_neighbor_cells(current_cell)
    var best_cell = current_cell
    var max_pheromone = 0.0

    for neighbor in neighbors:
        var pheromone = pheromone_map.get_pheromone(neighbor)

        # Add random exploration (not purely greedy)
        pheromone += randf() * 0.5

        if pheromone > max_pheromone:
            max_pheromone = pheromone
            best_cell = neighbor

    # Move toward best cell
    var target_pos = Vector2(best_cell.x * 10, best_cell.y * 10)
    velocity = (target_pos - global_position).normalized() * 50
    move_and_slide()

func get_neighbor_cells(cell: Vector2i) -> Array:
    return [
        cell + Vector2i(1, 0),
        cell + Vector2i(-1, 0),
        cell + Vector2i(0, 1),
        cell + Vector2i(0, -1),
    ]

# Result: Ant follows strongest pheromone trail with random exploration
[/code]

[hr]

[b]Emergence of Shortest Path[/b]

**Why does this find optimal routes?**

[color=yellow][b]Positive Feedback Loop:[/b][/color]
[code]
# 1. Ants explore randomly at first (no pheromone)
# 2. Some ants find food, return to nest
# 3. Successful ants deposit pheromone along their path
# 4. Other ants detect pheromone, prefer those paths
# 5. Shorter paths get more traffic (round-trip faster)
# 6. More traffic = more pheromone = more ants
# 7. Longer paths get less traffic, evaporate faster
# 8. Eventually, shortest path dominates

# Result: Collective optimization without planning
[/code]

**Stigmergy = indirect coordination** - no ant tells others where to go, environment itself guides.

[hr]

[b]Multiple Pheromone Types[/b]

**Different signals for different purposes:**

[color=yellow][b]Code: Food vs Danger Pheromones[/b][/color]
[code]
var pheromone_food = {}  # Leads to food
var pheromone_danger = {}  # Warns of threats

func ant_movement():
    var neighbors = get_neighbor_cells(current_cell)

    var best_cell = current_cell
    var max_score = -INF

    for neighbor in neighbors:
        var food_pheromone = pheromone_food.get(neighbor, 0.0)
        var danger_pheromone = pheromone_danger.get(neighbor, 0.0)

        # Attract to food, repel from danger
        var score = food_pheromone * 2.0 - danger_pheromone * 5.0
        score += randf() * 0.5  # Exploration

        if score > max_score:
            max_score = score
            best_cell = neighbor

    move_to(best_cell)

# When ant encounters enemy:
pheromone_danger[current_cell] = 10.0  # Warn others

# Result: Ants avoid dangerous areas, converge on safe food routes
[/code]

[hr]

[b]Diffusion (Pheromone Spread)[/b]

**Pheromones spread to adjacent cells:**

[color=yellow][b]Code: Simple Diffusion[/b][/color]
[code]
func diffuse_pheromones(delta: float):
    var diffusion_rate = 0.1
    var new_grid = {}

    for cell in pheromone_grid:
        var neighbors = get_neighbor_cells(cell)
        var total_diffused = 0.0

        # Spread to neighbors
        for neighbor in neighbors:
            var diffused_amount = pheromone_grid[cell] * diffusion_rate * delta
            total_diffused += diffused_amount

            if not new_grid.has(neighbor):
                new_grid[neighbor] = 0.0
            new_grid[neighbor] += diffused_amount

        # Reduce current cell by diffused amount
        if not new_grid.has(cell):
            new_grid[cell] = 0.0
        new_grid[cell] += pheromone_grid[cell] - total_diffused

    pheromone_grid = new_grid

# Result: Pheromone trails widen over time
# Smoother gradients, easier to follow
[/code]

[hr]

[b]Pheromone Visualization[/b]

**Draw pheromone strength as color:**

[color=yellow][b]Code: Debug Visualization[/b][/color]
[code]
func _draw():
    for cell in pheromone_grid:
        var strength = pheromone_grid[cell]

        if strength > 0.01:  # Only draw significant pheromone
            var pos = Vector2(cell.x * 10, cell.y * 10)
            var alpha = clamp(strength / 10.0, 0.0, 1.0)
            var color = Color(1, 0, 1, alpha)  # Magenta with variable alpha

            draw_rect(Rect2(pos, Vector2(10, 10)), color)

# Result: See pheromone trails as colored overlay
# Debugging and aesthetic visualization
[/code]

[hr]

[b]Ant Colony Optimization (ACO)[/b]

**Apply to pathfinding problems:**

[color=yellow][b]Code: ACO Pathfinding[/b][/color]
[code]
# Find path from start to goal using ant colony optimization

var ants = []
var best_path = []
var best_path_length = INF

func solve_with_aco(start: Vector2i, goal: Vector2i, iterations: int):
    for iteration in range(iterations):
        # Spawn ants at start
        for i in range(20):  # 20 ants per iteration
            var ant = spawn_ant(start)
            var path = ant.find_path_to(goal)

            if path.size() > 0:
                var path_length = path.size()

                # Deposit pheromone inversely proportional to length
                var deposit_amount = 100.0 / path_length

                for cell in path:
                    deposit_pheromone(cell, deposit_amount)

                # Track best path
                if path_length < best_path_length:
                    best_path = path
                    best_path_length = path_length

        # Evaporate pheromones
        evaporate_pheromones(0.1)

    return best_path

# Result: Converges to near-optimal path
# Good for dynamic environments (handles changes)
[/code]

**ACO advantages:**
- Adapts to changing environments
- Finds multiple good paths (not just one)
- Naturally parallelizable

[hr]

[b]Heat Maps (Accumulated Activity)[/b]

**Track where agents have been:**

[color=yellow][b]Code: Activity Heat Map[/b][/color]
[code]
var activity_map = {}

func record_activity(cell: Vector2i):
    if not activity_map.has(cell):
        activity_map[cell] = 0

    activity_map[cell] += 1

func get_activity_color(cell: Vector2i) -> Color:
    var activity = activity_map.get(cell, 0)
    var normalized = clamp(activity / 100.0, 0.0, 1.0)

    # Heat map: blue (cold) → red (hot)
    return Color(normalized, 0, 1.0 - normalized)

# Result: Visualize where ants travel most
# Reveals emergent paths, bottlenecks
[/code]

[hr]

[b]Trail Formation (Path Reinforcement)[/b]

**Persistent trails from repeated use:**

[color=yellow][b]Code: Permanent Trail Creation[/b][/color]
[code]
var permanent_trails = {}

func check_trail_formation():
    for cell in pheromone_grid:
        # If pheromone consistently high, make permanent trail
        if pheromone_grid[cell] > 8.0:
            permanent_trails[cell] = true

            # Modify terrain (place path tile)
            create_path_tile(cell)

# Result: Heavily-used routes become physical paths
# Environment permanently modified by agent activity
[/code]

**Stigmergy creates infrastructure** - trails become roads.

[hr]

[b]Foraging Simulation[/b]

**Complete ant colony foraging:**

[color=yellow][b]Code: Colony Behavior[/b][/color]
[code]
extends Node2D

var nest_position = Vector2i(50, 50)
var food_sources = [Vector2i(20, 80), Vector2i(80, 20)]
var ants = []

func _ready():
    # Spawn ants at nest
    for i in range(50):
        var ant = Ant.new()
        ant.position = nest_position
        ant.state = "searching"
        ants.append(ant)
        add_child(ant)

func _process(delta):
    for ant in ants:
        if ant.state == "searching":
            # Follow pheromone or explore
            ant.move_randomly_or_follow_pheromone()

            # Check if reached food
            if ant.current_cell in food_sources:
                ant.state = "returning"
                ant.carrying_food = true

        elif ant.state == "returning":
            # Return to nest, deposit pheromone
            ant.move_toward(nest_position)
            deposit_pheromone(ant.current_cell, 2.0)

            if ant.current_cell == nest_position:
                ant.state = "searching"
                ant.carrying_food = false

# Result: Colony self-organizes
# Efficient paths emerge without central planning
[/code]

[hr]

[b]Slime Mold Simulation (Physarum)[/b]

**Similar to ants, but continuous:**

[color=yellow][b]Concept: Multi-Agent Slime[/b][/color]
[code]
# Slime mold agents:
# 1. Sense pheromone in front-left, front, front-right
# 2. Turn toward strongest signal
# 3. Move forward
# 4. Deposit pheromone

func slime_agent_step():
    var sensors = [
        sense_pheromone(position, rotation - 0.5),  # Left
        sense_pheromone(position, rotation),        # Forward
        sense_pheromone(position, rotation + 0.5),  # Right
    ]

    # Turn toward strongest sensor
    var max_index = sensors.find(sensors.max())
    if max_index == 0:
        rotation -= turn_speed
    elif max_index == 2:
        rotation += turn_speed

    # Move forward
    position += Vector2.from_angle(rotation) * speed

    # Deposit pheromone
    deposit_pheromone(position, 5.0)

# Result: Slime network emerges
# Efficient transport networks (proven optimal for Tokyo rail)
[/code]

**Physarum polycephalum solves mazes** - real-world biological computer.

[hr]

[b]Applications Beyond Ants[/b]

**Pheromone-like systems everywhere:**

[color=yellow][b]1. Traffic Flow[/b][/color]
- Cars deposit "traffic" signal
- GPS routes avoid high-traffic areas
- Emergent optimal routing

[color=yellow][b]2. MMO Player Density[/b][/color]
- Track player activity heatmaps
- Spawn resources where players go
- Dynamic content distribution

[color=yellow][b]3. Dirt/Wear Trails[/b][/color]
- Accumulate "dirt" where player walks
- Visual trails show common paths
- Emergent environmental storytelling

[color=yellow][b]4. AI Squad Tactics[/b][/color]
- "Danger" pheromone from combat
- Squad members avoid dangerous zones
- Coordinate without communication

[hr]

[b]What Pheromone Trails Reveal[/b]

Pheromone trails show us:

1. **Coordination without communication** - Environment mediates
2. **Emergence from simple rules** - No ant knows optimal path, colony finds it
3. **Positive feedback creates paths** - More traffic → stronger trail → more traffic
4. **Evaporation prevents stagnation** - Old trails fade, adaptation possible
5. **Stigmergy is powerful** - Indirect cooperation through environment
6. **Local rules, global optimization** - Each ant sees only neighbors, colony optimizes
7. **Infrastructure emerges** - Trails become permanent modifications

**Pheromones are anarchist coordination** - no leader, no plan, just mutual adjustment through shared space.

**The environment is the message** - not commands, but traces left behind.

[hr]

[color=cyan][b]Summary:[/b][/color]
Pheromone trails enable stigmergic coordination - agents communicate by modifying environment. Ants deposit pheromones, others follow strongest trails. Evaporation prevents staleness. Positive feedback reinforces shorter paths (more traffic = stronger signal). Multiple pheromone types (food, danger). Diffusion spreads signals. Ant Colony Optimization (ACO) for pathfinding. Heat maps visualize activity. Trail formation creates permanent infrastructure. Applications: traffic routing, player density, wear patterns, AI tactics. Coordination without central control.

[hr]

[color=orange][b]Next:[/b] White Noise[/color]
If pheromones are accumulated signal, white noise is pure signal - maximum entropy, all frequencies equal, complete randomness. The baseline against which all other noise is measured.

'''
