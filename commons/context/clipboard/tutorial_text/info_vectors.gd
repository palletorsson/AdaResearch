var text = '''[b]Vectors[/b]
[i]Mathematics of Direction and Magnitude[/i]

Vectors are mathematical objects that represent both magnitude (length) and direction.

In programming, vectors are used to represent positions, velocities, accelerations, and forces. They allow us to model motion and physical interactions in 2D and 3D space.

[code]
# Vector declaration in Godot
var position = Vector2(100, 200)  # x=100, y=200
var velocity = Vector2(5, -3)     # Moving right and up

# Basic vector operations
position += velocity  # Vector addition
velocity *= 0.98      # Vector scaling (friction)

# Get vector properties
var speed = velocity.length()         # Magnitude
var direction = velocity.normalized() # Unit vector
[/code]

[hr]

[b]Vector Addition and Subtraction[/b]

Vector addition combines two or more vectors by adding their corresponding components.

Geometrically, it can be visualized using:
- The 'head-to-tail' method
- The parallelogram rule

Vector subtraction (A - B) gives the displacement vector from B to A.

[code]
var force1 = Vector2(10, 5)
var force2 = Vector2(-3, 8)

# Calculate resultant force
var resultant = force1 + force2

# Direction from object to target
var object_pos = Vector2(100, 100)
var target_pos = Vector2(200, 150)
var direction = target_pos - object_pos

# Distance between objects
var distance = direction.length()
[/code]

[hr]

[b]Multiplication and Normalization[/b]

Vectors can be multiplied by scalars to change their magnitude without changing direction.

[i]Normalization:[/i]
Creates a unit vector (length of 1) that preserves only direction information.

[i]Dot Product:[/i]
Returns a scalar value related to the angle between vectors:
- Returns 1 if vectors are aligned
- Returns 0 if vectors are perpendicular
- Returns -1 if vectors are opposite

[code]
var velocity = Vector2(3, 4)
velocity *= 2.5  # Increase speed

# Normalization
var direction = (target - position).normalized()

# Moving at consistent speed toward target
var speed = 5.0
velocity = direction * speed

# Dot product
var forward = Vector2(0, -1)
var to_target = (target - position).normalized()
var alignment = forward.dot(to_target)
[/code]

[hr]

[b]Forces and Motion[/b]

Newton's Second Law: Force = Mass × Acceleration

By accumulating forces and updating position based on velocity, we can create realistic physics simulations.

[code]
class Particle:
    var position = Vector2.ZERO
    var velocity = Vector2.ZERO
    var acceleration = Vector2.ZERO
    var mass = 1.0

    func apply_force(force):
        acceleration += force / mass

    func update(delta):
        velocity += acceleration * delta
        position += velocity * delta
        acceleration = Vector2.ZERO
        velocity *= 0.99  # Friction
[/code]

[hr]

[b]Vector Fields and Flow[/b]

Vector fields assign a vector to each point in space, creating flow patterns that particles can follow.

[i]Applications:[/i]
- Simulating fluids and water flow
- Crowd movement simulation
- Wind effects in games
- Dynamic terrain effects

[code]
func get_field_vector(position):
    var center = Vector2(width/2, height/2)
    var offset = position - center

    # Create perpendicular vector for circular motion
    var perpendicular = Vector2(-offset.y, offset.x).normalized()

    # Scale by distance from center
    var distance = offset.length()
    var strength = max(0, 1 - distance/200)

    return perpendicular * strength * 5.0
[/code]
'''
