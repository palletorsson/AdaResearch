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
