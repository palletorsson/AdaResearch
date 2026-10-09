# Soft Body Deformation

A cube made of springs. Push it; watch it deform.

Build a mass-spring lattice.

```gdscript
class_name MassSpringCube extends Node3D

var masses: Array = []      # Vector3 positions
var velocities: Array = []
var springs: Array = []     # [idx_a, idx_b, rest_length, stiffness]
@export var size: int = 3

func build() -> void:
    masses.clear()
    velocities.clear()
    for z in size:
        for y in size:
            for x in size:
                masses.append(Vector3(x, y, z) * 0.5)
                velocities.append(Vector3.ZERO)
```

A 3D grid of point masses. Each stores a position and a velocity.

Connect adjacent masses with springs.

```gdscript
func add_springs() -> void:
    springs.clear()
    for z in size:
        for y in size:
            for x in size:
                var i := index_of(x, y, z)
                if x + 1 < size: springs.append([i, index_of(x + 1, y, z), 0.5, 20.0])
                if y + 1 < size: springs.append([i, index_of(x, y + 1, z), 0.5, 20.0])
                if z + 1 < size: springs.append([i, index_of(x, y, z + 1), 0.5, 20.0])

func index_of(x: int, y: int, z: int) -> int:
    return z * size * size + y * size + x
```

Edge springs keep the cube's shape. Rest length matches the grid spacing.

Compute spring forces.

```gdscript
func compute_forces() -> Array:
    var forces: Array = []
    for _i in masses.size(): forces.append(Vector3.ZERO)
    for spring in springs:
        var a: Vector3 = masses[spring[0]]
        var b: Vector3 = masses[spring[1]]
        var direction: Vector3 = b - a
        var current_length: float = direction.length()
        var extension: float = current_length - spring[2]
        var force: Vector3 = direction.normalized() * extension * spring[3]
        forces[spring[0]] += force
        forces[spring[1]] -= force
    return forces
```

Each spring pulls its endpoints toward its rest length. Equal and opposite forces on the two ends.

Integrate.

```gdscript
@export var damping: float = 0.5

func _physics_process(delta: float) -> void:
    var forces := compute_forces()
    for i in masses.size():
        velocities[i] += forces[i] * delta
        velocities[i] *= (1.0 - damping * delta)
        masses[i] += velocities[i] * delta
```

Euler integration with velocity damping. Damping prevents unbounded oscillation.

Apply an external push.

```gdscript
func apply_push(push_position: Vector3, force: Vector3, radius: float = 0.5) -> void:
    for i in masses.size():
        var distance: float = masses[i].distance_to(push_position)
        if distance < radius:
            var falloff: float = 1.0 - distance / radius
            velocities[i] += force * falloff
```

Nearby masses take more force. The push produces a travelling wave through the lattice.

Rebuild the mesh each frame.

```gdscript
func rebuild_mesh() -> void:
    var mesh := ArrayMesh.new()
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for face in cube_faces():
        for vi in face:
            st.add_vertex(masses[vi])
    st.generate_normals()
    mesh_instance.mesh = st.commit()
```

The visible cube follows the masses. Deformation is visible as warping of the mesh.

You can now build a mass-spring lattice, compute forces, integrate, apply pushes, and rebuild the visual mesh. SoftBodies_Carusell extends into rotating soft bodies.
