# Vectors
Mathematics of Direction and Magnitude

Vectors are mathematical objects that represent both magnitude (length) and direction.

In programming, vectors are used to represent positions, velocities, accelerations, and forces. They allow us to model motion and physical interactions in 2D and 3D space.

```
# Vector declaration in Godot
var position = Vector2(100, 200)  # x=100, y=200
var velocity = Vector2(5, -3)     # Moving right and up

# Basic vector operations
position += velocity  # Vector addition
velocity *= 0.98      # Vector scaling (friction)

# Get vector properties
var speed = velocity.length()         # Magnitude
var direction = velocity.normalized() # Unit vector
```

---

## Vector Addition and Subtraction

Vector addition combines two or more vectors by adding their corresponding components.

Geometrically, it can be visualized using:
- The