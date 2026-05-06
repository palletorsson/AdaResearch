<<<ADA_BUNDLE>>>
sequence: lsystems
file: tutorial.md
maps: 7
skipped_passing: 0
created: 2026-04-24T03:10:00
only_failing: true
diff_mode: false
with_context: true
<<</ADA_BUNDLE>>>

<<<MAP: LSystems_Grammar_Lab>>>
# Grammar Lab

Axiom, rules, generations. An L-system rewrites a string.

Define an L-system.

```gdscript
class_name LSystem extends Resource

@export var axiom: String = "F"
@export var rules: Dictionary = {"F": "F+F-F-F+F"}
@export var angle_deg: float = 90.0
```

The axiom is the starting string. The rules map symbols to their replacements.

Expand by one generation.

```gdscript
func expand_once(current: String) -> String:
    var result: String = ""
    for c in current:
        result += rules.get(c, c)
    return result
```

Every character is looked up in the rules. Characters not in the rules pass through unchanged.

Expand several generations.

```gdscript
func expand(generations: int) -> String:
    var current: String = axiom
    for _i in generations:
        current = expand_once(current)
    return current
```

Each generation is a string. Length grows exponentially when rules expand to longer strings.

Apply the Koch rule.

```gdscript
var koch_system := LSystem.new()
koch_system.axiom = "F"
koch_system.rules = {"F": "F+F-F-F+F"}
koch_system.angle_deg = 90.0

var string := koch_system.expand(4)
# Result: 256 characters after 4 generations
```

Classic Koch curve rule. Each F becomes a kink.

Interpret the string with a turtle.

```gdscript
class_name Turtle2D

var position: Vector2 = Vector2.ZERO
var heading: float = 0.0  # radians
var segments: Array = []

func interpret(lstring: String, step: float, angle_rad: float) -> void:
    for c in lstring:
        match c:
            "F":
                var end := position + Vector2(cos(heading), sin(heading)) * step
                segments.append([position, end])
                position = end
            "+":
                heading += angle_rad
            "-":
                heading -= angle_rad
```

F draws a line forward; + rotates left; - rotates right. Classic turtle-graphics commands.

Render the segments.

```gdscript
func render_segments(turtle: Turtle2D) -> void:
    for seg in turtle.segments:
        draw_line(seg[0], seg[1])
```

Each segment becomes a line in the scene. The shape emerges from the string interpretation.

Tree rule with branches.

```gdscript
var tree_system := LSystem.new()
tree_system.axiom = "F"
tree_system.rules = {"F": "F[+F]F[-F]F"}
tree_system.angle_deg = 25.0
```

[ pushes the turtle state; ] pops it. The turtle splits off to draw a branch, then returns.

Implement stack commands.

```gdscript
var stack: Array = []

func push_state() -> void:
    stack.append({"position": position, "heading": heading})

func pop_state() -> void:
    var s = stack.pop_back()
    position = s.position
    heading = s.heading
```

Push before branching; pop after. The turtle returns to its original state to continue the trunk.

You can now define an L-system, expand it, interpret the result with a turtle, and render the segments. LSystems_Growth extends the L-system into animated time-lapse growth.

<<<MAP: LSystems_Growth>>>
# Growth

Watch the L-system grow. One generation per visible step.

Animate by generations.

```gdscript
class_name GrowthAnimator extends Node

@export var lsystem: LSystem
@export var generations_per_second: float = 0.5

var current_generation: int = 0
var time_accumulator: float = 0.0

func _process(delta: float) -> void:
    time_accumulator += delta
    if time_accumulator > 1.0 / generations_per_second:
        time_accumulator = 0.0
        current_generation += 1
        rebuild_to_generation(current_generation)
```

Half a second per generation. The plant grows in visible steps.

Rebuild at a specific generation.

```gdscript
func rebuild_to_generation(gen: int) -> void:
    clear_segments()
    var string := lsystem.expand(gen)
    var turtle := Turtle3D.new()
    turtle.interpret(string, 0.2, deg_to_rad(lsystem.angle_deg))
    render_segments_3d(turtle.segments)
```

Clear the previous generation's geometry, compute the new string, interpret it, render the result.

Use a 3D turtle.

```gdscript
class_name Turtle3D

var position: Vector3 = Vector3.ZERO
var direction: Vector3 = Vector3.UP
var right: Vector3 = Vector3.RIGHT
var up: Vector3 = Vector3.FORWARD
var segments: Array = []
var stack: Array = []

func interpret(lstring: String, step: float, angle_rad: float) -> void:
    for c in lstring:
        match c:
            "F":
                var end := position + direction * step
                segments.append([position, end])
                position = end
            "+": direction = direction.rotated(right, angle_rad)
            "-": direction = direction.rotated(right, -angle_rad)
            "&": direction = direction.rotated(up, angle_rad)
            "^": direction = direction.rotated(up, -angle_rad)
            "[": stack.append({"p": position, "d": direction, "r": right, "u": up})
            "]":
                var s = stack.pop_back()
                position = s.p; direction = s.d; right = s.r; up = s.u
```

Three-dimensional turtle. Six rotation commands cover pitch, yaw, and the stack operations.

Spawn a plant stalk.

```gdscript
class_name PlantStalk extends Node3D

@export var grow_rate: float = 0.3

var current_height: float = 0.0
@export var max_height: float = 3.0

func _process(delta: float) -> void:
    current_height = min(max_height, current_height + grow_rate * delta)
    var mesh: CylinderMesh = mesh_instance.mesh
    mesh.height = current_height
    mesh_instance.position.y = current_height / 2.0
```

The stalk extends over time. The cylinder mesh's height and the mesh instance's position both update.

Add leaves at the tips.

```gdscript
func spawn_leaf_at(position: Vector3) -> Node3D:
    var leaf := MeshInstance3D.new()
    leaf.mesh = preload("res://commons/lsystems/leaf.tscn").instantiate().mesh
    leaf.position = position
    leaf.scale = Vector3.ONE * 0.3
    add_child(leaf)
    return leaf
```

A leaf mesh at each terminal segment. Small scale so leaves don't overwhelm the stalk.

Vary per-plant.

```gdscript
func randomize_parameters(plant: PlantStalk) -> void:
    plant.grow_rate = randf_range(0.2, 0.5)
    plant.max_height = randf_range(2.0, 4.0)
    plant.rotate_y(randf_range(0, TAU))
```

Each plant gets slightly different parameters. A garden of plants reads as a population rather than as copies.

You can now animate L-system growth by generations, interpret the result with a 3D turtle, and populate a scene with varied plants. LSystems_Grammars_And_Curves extends into different curve grammars.

<<<MAP: LSystems_Grammars_And_Curves>>>
# Grammars and Curves

Different rules produce different curves. Each rule is a shape's DNA.

Koch snowflake.

```gdscript
var koch := LSystem.new()
koch.axiom = "F--F--F"  # triangle
koch.rules = {"F": "F+F--F+F"}
koch.angle_deg = 60.0
```

Starts as a triangle. Each F expands to a kink; four generations produce the snowflake.

Dragon curve.

```gdscript
var dragon := LSystem.new()
dragon.axiom = "FX"
dragon.rules = {
    "X": "X+YF+",
    "Y": "-FX-Y",
}
dragon.angle_deg = 90.0
```

Two non-terminal symbols, X and Y. The dragon curve folds on itself at right angles.

Hilbert curve.

```gdscript
var hilbert := LSystem.new()
hilbert.axiom = "A"
hilbert.rules = {
    "A": "+BF-AFA-FB+",
    "B": "-AF+BFB+FA-",
}
hilbert.angle_deg = 90.0
```

Space-filling curve. Each generation packs more detail into the same region.

Sierpinski triangle.

```gdscript
var sierpinski := LSystem.new()
sierpinski.axiom = "A"
sierpinski.rules = {
    "A": "B-A-B",
    "B": "A+B+A",
}
sierpinski.angle_deg = 60.0
```

Two mutually recursive rules. The interpretation treats both A and B as F for drawing.

Implement drawing for any symbol.

```gdscript
func interpret_curve(lstring: String, step: float, angle_rad: float) -> Array:
    var segments: Array = []
    var position := Vector2.ZERO
    var heading: float = 0.0
    for c in lstring:
        match c:
            "F", "A", "B":
                var end := position + Vector2(cos(heading), sin(heading)) * step
                segments.append([position, end])
                position = end
            "+":
                heading += angle_rad
            "-":
                heading -= angle_rad
    return segments
```

Treat all non-terminals as drawing commands. The logical distinction between A and B matters for the rewrite; the interpretation ignores it.

Normalise the scale.

```gdscript
func fit_to_bounds(segments: Array, target_size: Vector2) -> Array:
    var min_p := Vector2.INF; var max_p := -Vector2.INF
    for seg in segments:
        min_p = min_p.min(seg[0]); min_p = min_p.min(seg[1])
        max_p = max_p.max(seg[0]); max_p = max_p.max(seg[1])
    var span: Vector2 = max_p - min_p
    var scale: float = min(target_size.x / span.x, target_size.y / span.y)
    var offset: Vector2 = -min_p * scale
    var scaled: Array = []
    for seg in segments:
        scaled.append([seg[0] * scale + offset, seg[1] * scale + offset])
    return scaled
```

Measure the bounding box, compute a scale that fits, apply it. The curve renders at consistent size regardless of generation.

Render side by side.

```gdscript
func render_gallery(systems: Array, positions: Array) -> void:
    for i in systems.size():
        var lstring: String = systems[i].expand(4)
        var segments: Array = interpret_curve(lstring, 0.1, deg_to_rad(systems[i].angle_deg))
        segments = fit_to_bounds(segments, Vector2(2, 2))
        render_at_position(segments, positions[i])
```

Four grammars at four positions. The gallery makes the grammar-curve relationship comparative.

You can now encode multiple grammars, interpret them uniformly, fit each to a target bounding box, and render them side by side. LSystems_Architecture extends L-systems into building-scale form.

<<<MAP: LSystems_Architecture>>>
# LSystems Architecture

L-systems build buildings. Rules become floor plans.

Encode a skyscraper grammar.

```gdscript
var skyscraper := LSystem.new()
skyscraper.axiom = "B"
skyscraper.rules = {
    "B": "F[B]F[B]B",  # base branches into tiers
    "F": "F",
}
skyscraper.angle_deg = 0.0  # vertical only
```

Base B expands into stacked tiers. Each tier branches vertically; the F represents a floor.

Interpret in 3D.

```gdscript
func interpret_building(lstring: String, floor_height: float) -> Node3D:
    var building := Node3D.new()
    var current_y: float = 0.0
    for c in lstring:
        match c:
            "F":
                spawn_floor(building, current_y, floor_height)
                current_y += floor_height
            "[", "]":
                pass  # branches handled separately
    return building
```

F commands stack floors vertically. The building's height grows with the string length.

Spawn a floor slab.

```gdscript
func spawn_floor(parent: Node3D, y: float, height: float) -> void:
    var mesh := MeshInstance3D.new()
    mesh.mesh = BoxMesh.new()
    mesh.scale = Vector3(2, height, 2)
    mesh.position = Vector3(0, y + height / 2, 0)
    parent.add_child(mesh)
```

One slab per floor. Scale matches the floor's footprint.

Encode a temple grammar.

```gdscript
var temple := LSystem.new()
temple.axiom = "T"
temple.rules = {
    "T": "CR[+C][-C]P",  # temple: columns, roof, steps
    "C": "F",            # column as single tall prism
    "R": "F",            # roof as single block
    "P": "F",            # pediment
}
```

Different grammar, different structure. The architectural vocabulary expands with the rule set.

Vary the grammar.

```gdscript
func generate_variant(base_system: LSystem, mutation_rate: float = 0.1) -> LSystem:
    var variant := base_system.duplicate(true)
    for key in variant.rules:
        if randf() < mutation_rate:
            variant.rules[key] = mutate_rule(variant.rules[key])
    return variant
```

Each variant is a small change to the grammar. Many variants together read as a town of related buildings.

Mutate a rule.

```gdscript
func mutate_rule(rule: String) -> String:
    var i: int = randi() % rule.length()
    var mutation_type: int = randi() % 3
    match mutation_type:
        0: return rule.insert(i, "F")  # add a floor
        1: if rule.length() > 1: return rule.erase(i, 1)  # remove
        2: return rule.insert(i, "[F]")  # add a branch
    return rule
```

Three mutation types: insertion, deletion, branch. Each produces a small variation from the parent rule.

Compose a skyline.

```gdscript
func build_skyline(count: int, systems: Array) -> void:
    for i in count:
        var system: LSystem = systems[i % systems.size()]
        var string := system.expand(3 + randi() % 3)
        var building := interpret_building(string, 0.5)
        building.position = Vector3(i * 3, 0, 0)
        add_child(building)
```

A row of buildings, each from a (possibly varied) grammar. The skyline becomes a set of grammars rendered together.

You can now encode architectural grammars, interpret them as 3D structures, vary them via mutation, and compose a skyline from varied buildings. LSystems_Competition extends L-systems into populations.

<<<MAP: LSystems_Competition>>>
# Competition

Plants compete for light. The L-system that reaches the sun first wins.

Track sunlight at each point.

```gdscript
class_name LightField extends Node

var occluders: Array = []  # list of (position, radius) tuples

func light_at(point: Vector3) -> float:
    var above: Vector3 = point + Vector3.UP * 10
    var occlusion: float = 0.0
    for occ in occluders:
        var segment_distance: float = segment_to_point_distance(point, above, occ.position)
        if segment_distance < occ.radius:
            occlusion += 1.0 - segment_distance / occ.radius
    return max(0.0, 1.0 - occlusion)
```

Ray from point to directly above. Each occluder within range reduces the light. Value 0 is full shade; 1 is full sun.

Grow a plant proportional to its available light.

```gdscript
class_name LightCompetingPlant extends LSystemPlant

@export var max_height: float = 4.0

var growth_rate: float = 0.0

func _process(delta: float) -> void:
    var light: float = light_field.light_at(global_position + Vector3.UP * current_height)
    growth_rate = lerp(growth_rate, light * 0.5, delta * 2.0)
    current_height = min(max_height, current_height + growth_rate * delta)
```

More light, faster growth. Plants that start taller cast shadow on shorter ones, reinforcing their advantage.

Register the plant as an occluder.

```gdscript
func register_as_occluder() -> void:
    light_field.occluders.append({
        "position": global_position + Vector3.UP * current_height * 0.5,
        "radius": current_height * 0.3,
    })
```

Each plant's canopy blocks light for its neighbours. Position and radius scale with the plant's height.

Spawn a population.

```gdscript
func spawn_population(count: int, bounds: Vector2) -> void:
    for _i in count:
        var p := LightCompetingPlant.new()
        p.position = Vector3(randf_range(0, bounds.x), 0, randf_range(0, bounds.y))
        p.max_height = randf_range(2.0, 5.0)
        p.growth_rate = randf_range(0.2, 0.8)
        add_child(p)
```

Twenty or so plants, randomly placed and sized. The genetic variation drives the competition.

Run the generation timer.

```gdscript
@export var generation_interval: float = 10.0  # seconds

func _ready() -> void:
    var timer := Timer.new()
    timer.wait_time = generation_interval
    timer.timeout.connect(next_generation)
    add_child(timer)
    timer.start()

func next_generation() -> void:
    cull_weak()
    reproduce_strong()
```

Every ten seconds, the population iterates: weak plants die, strong plants reproduce. Evolution through generations.

Cull plants below a height threshold.

```gdscript
func cull_weak() -> void:
    for child in get_children():
        if child is LightCompetingPlant and child.current_height < 1.0:
            child.queue_free()
```

Plants that failed to grow past one unit are removed. Weaker genetic lines die out.

Reproduce the strong.

```gdscript
func reproduce_strong() -> void:
    var strong: Array = get_children().filter(func(p): return p.current_height > 3.0)
    for parent in strong.slice(0, 3):  # top 3 reproduce
        for _i in 2:
            var offspring := LightCompetingPlant.new()
            offspring.position = parent.position + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
            offspring.max_height = parent.max_height + randf_range(-0.5, 0.5)
            add_child(offspring)
```

Top three plants each spawn two offspring. Offspring inherit parent traits with mutation.

You can now grow plants under a light field, register them as occluders, cull weak competitors, and reproduce the strong. LSystems_Living extends L-systems into a full ecosystem.

<<<MAP: LSystems_Living>>>
# Living

The L-system becomes the world. Terrain itself follows grammar.

Generate a terrain patch via L-system.

```gdscript
func generate_terrain(lstring: String, grid_size: Vector2i) -> Array:
    var heightmap: Array = []
    var cursor_x: int = 0; var cursor_y: int = 0
    for y in grid_size.y:
        heightmap.append([])
        for x in grid_size.x:
            heightmap[y].append(0.0)
    for c in lstring:
        match c:
            "F":
                if cursor_x >= 0 and cursor_x < grid_size.x and cursor_y >= 0 and cursor_y < grid_size.y:
                    heightmap[cursor_y][cursor_x] += 1.0
                cursor_x += 1
            "+": cursor_y += 1
            "-": cursor_y -= 1
    return heightmap
```

F raises a cell by one; +/- advance the cursor. The string becomes a terrain.

Render the terrain as a mesh.

```gdscript
func heightmap_to_mesh(heightmap: Array) -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for y in heightmap.size() - 1:
        for x in heightmap[0].size() - 1:
            add_quad(st, heightmap, x, y)
    st.generate_normals()
    return st.commit()
```

Each grid cell becomes two triangles. The heightmap drives the vertex Y coordinates.

Plant trees following grammar.

```gdscript
func plant_trees_from_grammar(lstring: String) -> void:
    var position := Vector3.ZERO
    for c in lstring:
        match c:
            "T":
                spawn_tree(position)
            "F":
                position += Vector3.FORWARD * 2
            "+":
                position = position.rotated(Vector3.UP, PI / 8)
```

T spawns a tree; F moves forward; + rotates. The tree-placement pattern follows the L-system's rhythm.

Use the sculpted artifact.

```gdscript
class_name GeneticTreeSculptor extends Node3D

@export var depth: int = 5
@export var branch_forks: int = 2
@export var branch_angle: float = 25.0
@export var length_taper: float = 0.75

func regenerate() -> void:
    var system := LSystem.new()
    system.axiom = "F"
    system.rules = {"F": generate_rule_from_params()}
    system.angle_deg = branch_angle
    interpret_and_display(system.expand(depth))
```

Exposed parameters drive a parameterised rule. The learner adjusts sliders; the tree regenerates.

Generate the rule.

```gdscript
func generate_rule_from_params() -> String:
    var rule: String = "F["
    for _i in branch_forks:
        rule += "+F]["
    for _i in branch_forks:
        rule += "-F]"
    rule += "F"
    return rule
```

More forks means more branching; higher angle means wider spread. The rule's structure reflects the learner's choices.

Plant into the ecosystem.

```gdscript
func plant_authored_tree() -> void:
    var tree := spawn_tree_from_rule(current_rule)
    tree.global_position = spawn_point.global_position
    tree.add_to_group("ecosystem_trees")
    light_field.register_tree(tree)
```

The planted tree joins the ecosystem. It competes for light with existing plants.

You can now generate terrain from an L-system, render it as a mesh, plant trees following grammar, configure a parametric tree sculptor, and plant into the live ecosystem. Chamber_LSystems closes the sequence with grammars in contact.

<<<MAP: Chamber_LSystems>>>
# Chamber LSystems

Grammar meets grammar. The vine responds with laterals.

Build the branching catalyst.

```gdscript
class_name BranchingCatalyst extends Node3D

@export var rule: String = "F[+F][-F]F"
@export var expansion_depth: int = 2
@export var angle_deg: float = 25.0

func fire(direction: Vector3) -> void:
    var projectile := TENDRIL_PROJECTILE_SCENE.instantiate()
    projectile.global_position = global_position
    projectile.linear_velocity = direction * 8.0
    projectile.rule = rule
    projectile.depth = expansion_depth
    projectile.angle_deg = angle_deg
    get_tree().root.add_child(projectile)
```

The projectile carries the L-system parameters. On impact, the grammar expands into geometry.

Grow tendrils on impact.

```gdscript
class_name TendrilProjectile extends RigidBody3D

var rule: String
var depth: int
var angle_deg: float

func _on_body_entered(body: Node) -> void:
    var system := LSystem.new()
    system.axiom = "F"
    system.rules = {"F": rule}
    system.angle_deg = angle_deg
    var lstring := system.expand(depth)
    spawn_geometry_from_string(lstring, global_position, -linear_velocity.normalized())
    queue_free()
```

The projectile's geometry is generated at the impact point. After growing, the projectile is discarded.

Spawn geometry from the string.

```gdscript
func spawn_geometry_from_string(lstring: String, origin: Vector3, direction: Vector3) -> void:
    var turtle := Turtle3D.new()
    turtle.position = origin
    turtle.direction = direction
    turtle.interpret(lstring, 0.3, deg_to_rad(angle_deg))
    for seg in turtle.segments:
        spawn_segment(seg[0], seg[1])
```

Each segment becomes a small cylinder. The whole tendril emerges in one frame.

Build the branching vine creature.

```gdscript
class_name BranchingVine extends CharacterBody3D

@export var vine_rule: String = "F[+F]F[-F]"
@export var vine_angle_deg: float = 20.0

func respond_to_catalyst(catalyst_position: Vector3) -> void:
    var direction: Vector3 = (catalyst_position - global_position).normalized()
    spawn_lateral_in_direction(direction)
```

The vine grows a lateral toward the catalyst. Its rule is simpler than the catalyst's but similar in shape.

Spawn a lateral.

```gdscript
func spawn_lateral_in_direction(direction: Vector3) -> void:
    var system := LSystem.new()
    system.axiom = "F"
    system.rules = {"F": vine_rule}
    system.angle_deg = vine_angle_deg
    var lstring := system.expand(2)
    var turtle := Turtle3D.new()
    turtle.position = global_position
    turtle.direction = direction
    turtle.interpret(lstring, 0.4, deg_to_rad(vine_angle_deg))
    for seg in turtle.segments:
        spawn_lateral_segment(seg[0], seg[1])
```

The lateral responds to where the catalyst came from. Its growth direction matches the incoming projectile's.

Track intersection points.

```gdscript
func intersection_log() -> Array:
    var intersections: Array = []
    for tendril in get_tree().get_nodes_in_group("catalyst_tendril"):
        for lateral in get_tree().get_nodes_in_group("vine_lateral"):
            if tendril.global_position.distance_to(lateral.global_position) < 0.3:
                intersections.append(tendril.global_position)
    return intersections
```

Where catalyst tendril and vine lateral meet, the hybrid structure emerges. Intersection points are logged for the science screen.

Trace the rewrite history.

```gdscript
class_name RewriteTrace extends Node3D

var history: Array = []

func log_expansion(source: String, gen: int, expanded: String) -> void:
    history.append({
        "source": source,
        "generation": gen,
        "expanded": expanded.substr(0, 40),
        "time": Time.get_ticks_msec() / 1000.0,
    })
    redraw_trace_display()
```

Each expansion is a row in the history. The science screen reads both grammars in parallel.

You can now build the branching catalyst, project L-system tendrils, grow vine laterals in response, track catalyst-vine intersections, and log the rewrite history for both grammars. The L-Systems sequence closes with grammar as shared language.
