# Randomness_Examples_of_Randomness - Technical Documentation

## Core Concept in Code

### Pollock Drip Painting

```gdscript
extends Node3D

@export var drip_count := 500
@export var canvas_size := Vector2(10, 10)
@export var gravity := 9.8
@export var viscosity := 0.1

var line_renderer: ImmediateMesh
var rng := RandomNumberGenerator.new()

func _ready():
    rng.randomize()
    line_renderer = ImmediateMesh.new()
    generate_painting()

func generate_painting():
    line_renderer.clear_surfaces()
    line_renderer.surface_begin(Mesh.PRIMITIVE_LINES)

    for i in range(drip_count):
        simulate_drip()

    line_renderer.surface_end()

func simulate_drip():
    # Random start position (hand position over canvas)
    var pos = Vector3(
        rng.randf_range(-canvas_size.x/2, canvas_size.x/2),
        rng.randf_range(0.5, 2.0),  # Height above canvas
        rng.randf_range(-canvas_size.y/2, canvas_size.y/2)
    )

    # Random initial velocity (arm movement)
    var vel = Vector3(
        rng.randf_range(-2, 2),
        rng.randf_range(-0.5, 0.5),
        rng.randf_range(-2, 2)
    )

    var color = random_color()
    var prev_pos = pos

    # Simulate until paint hits canvas
    while pos.y > 0:
        line_renderer.surface_set_color(color)
        line_renderer.surface_add_vertex(prev_pos)
        line_renderer.surface_add_vertex(pos)

        prev_pos = pos

        # Physics
        vel.y -= gravity * 0.01
        vel *= (1.0 - viscosity * 0.01)
        vel += random_air_resistance()

        pos += vel * 0.01

func random_color() -> Color:
    # Pollock palette: blacks, whites, yellows, reds
    var colors = [
        Color.BLACK,
        Color.WHITE,
        Color(0.9, 0.8, 0.2),  # Yellow
        Color(0.8, 0.2, 0.2),  # Red
        Color(0.3, 0.3, 0.3),  # Gray
    ]
    return colors[rng.randi() % colors.size()]

func random_air_resistance() -> Vector3:
    return Vector3(
        rng.randfn(0, 0.1),
        rng.randfn(0, 0.05),
        rng.randfn(0, 0.1)
    )
```

### Pipe Dream

```gdscript
extends Node3D

@export var segment_length := 1.0
@export var max_segments := 100
@export var pipe_radius := 0.1

var current_pos := Vector3.ZERO
var current_dir := Vector3.FORWARD
var rng := RandomNumberGenerator.new()

func _ready():
    rng.randomize()
    generate_pipes()

func generate_pipes():
    for i in range(max_segments):
        create_segment()
        if should_turn():
            turn_random_direction()
        else:
            current_pos += current_dir * segment_length

func create_segment():
    var pipe = CSGCylinder3D.new()
    pipe.radius = pipe_radius
    pipe.height = segment_length

    # Orient along current direction
    pipe.position = current_pos + current_dir * segment_length / 2
    pipe.look_at(pipe.position + current_dir, Vector3.UP)
    pipe.rotate_object_local(Vector3.RIGHT, PI/2)

    add_child(pipe)

func should_turn() -> bool:
    return rng.randf() < 0.3  # 30% chance to turn

func turn_random_direction():
    var options = [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT]
    # Remove opposite direction (no 180° turns)
    options.erase(-current_dir)
    current_dir = options[rng.randi() % options.size()]

    # Add elbow joint
    create_elbow()

func create_elbow():
    var sphere = CSGSphere3D.new()
    sphere.radius = pipe_radius * 1.5
    sphere.position = current_pos
    add_child(sphere)
```

### Random Butterflies

```gdscript
class_name RandomButterfly
extends Node3D

var velocity := Vector3.ZERO
var target := Vector3.ZERO
var rng := RandomNumberGenerator.new()
var wing_phase := 0.0

@export var speed := 2.0
@export var wander_strength := 1.0
@export var bounds := Vector3(5, 3, 5)

func _ready():
    rng.randomize()
    pick_new_target()

func _process(delta):
    # Wing flapping
    wing_phase += delta * 10
    animate_wings()

    # Movement toward target with randomness
    var direction = (target - position).normalized()
    var wander = random_wander()

    velocity = velocity.lerp(direction * speed + wander, delta * 2)
    position += velocity * delta

    # Look in movement direction
    if velocity.length() > 0.1:
        look_at(position + velocity, Vector3.UP)

    # Pick new target when close
    if position.distance_to(target) < 1.0:
        pick_new_target()

func random_wander() -> Vector3:
    return Vector3(
        rng.randfn(0, wander_strength),
        rng.randfn(0, wander_strength * 0.5),
        rng.randfn(0, wander_strength)
    )

func pick_new_target():
    target = Vector3(
        rng.randf_range(-bounds.x, bounds.x),
        rng.randf_range(0.5, bounds.y),
        rng.randf_range(-bounds.z, bounds.z)
    )

func animate_wings():
    # Oscillate wing rotation
    var angle = sin(wing_phase) * 0.5
    $LeftWing.rotation.z = angle
    $RightWing.rotation.z = -angle
```

### Extreme Randomness

```gdscript
extends Node3D

@export var particle_count := 1000
@export var chaos_level := 1.0

var particles := []
var rng := RandomNumberGenerator.new()

func _ready():
    rng.randomize()
    create_particles()

func _process(delta):
    for p in particles:
        # Maximum chaos: completely random position each frame
        p.position = Vector3(
            rng.randfn(0, chaos_level),
            rng.randfn(0, chaos_level),
            rng.randfn(0, chaos_level)
        )
        # Random color
        p.material_override.albedo_color = Color(
            rng.randf(),
            rng.randf(),
            rng.randf()
        )
        # Random scale
        var s = rng.randf_range(0.01, 0.1)
        p.scale = Vector3(s, s, s)
```

## Map-Specific Configuration

### Structure Analysis
- 12×12 symmetric grid
- Simple perimeter wall (height 2)
- Floor at height 1
- Gallery layout with exhibits at corners

### Exhibit Placement
- Northwest (2,2): Pollock - fine art
- Northeast (8,2): Pipes - computer graphics
- Southwest (2,8): Butterflies - nature
- Southeast (8,8): Extreme - limits
- South exit (10,11): Moss - organic

## Key Takeaways

1. **Randomness enables art** - From Pollock to generative graphics
2. **Different applications, same principles** - All use controlled randomness
3. **Chaos has limits** - Extreme randomness becomes noise
4. **Nature uses randomness creatively** - Butterfly flight, moss growth

## Related Systems
- Particle systems
- ImmediateMesh for procedural geometry
- CSG for constructive solid geometry
- Noise functions for organic variation
