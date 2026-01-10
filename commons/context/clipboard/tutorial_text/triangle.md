## Axiom 1 — The Definition of a Triangle

A Line in the 3-dimensional coordinate system is a vector representing a position in **x, y, z**.

Code:

```
var Line_position = Vector3(0, 0, 0)
```

The vector (0, 0, 0) is the **origin** — the root of all vectors.

⚠️ This Line is not visible; it needs representation.

## Axiom 2 — The Visible Line

A visible Line can be represented by a small sphere placed at its position.

Code:

```
var sphere_mesh = SphereMesh.new()
var radius = 0.02  # a small sphere
sphere_mesh.radius = radius
sphere_mesh.height = radius * 2  # SphereMesh height is double radius
```

## Axiom 2.5 — The Mesh in the World

A mesh must be instantiated as a scene object to exist in the world.

Code:

```
var mesh_instance = MeshInstance3D.new()
mesh_instance.mesh = sphere_mesh
mesh_instance.position = Line_position
add_child(mesh_instance)
```

## Axiom 3 — Identity of a Line

The identity of a Line is represented as a **text label** positioned close to the Line.

Code:

```
var label_3d = Label3D.new()
label_3d.text = str(Line_position)
var label_offset = Vector3(0, 0.15, 0)
label_3d.position = Line_position + label_offset
label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
add_child(label_3d)
```

💡 Tip: Always ensure proper null checks and that the node has a valid parent before adding children.
## Axiom 1 — The Definition of a Line

A Line in the 3-dimensional coordinate system is a vector representing a position in **x, y, z**.

Code:

```
var Line_position = Vector3(0, 0, 0)
```

The vector (0, 0, 0) is the **origin** — the root of all vectors.

⚠️ This Line is not visible; it needs representation.

## Axiom 2 — The Visible Line

A visible Line can be represented by a small sphere placed at its position.

Code:

```
var sphere_mesh = SphereMesh.new()
var radius = 0.02  # a small sphere
sphere_mesh.radius = radius
sphere_mesh.height = radius * 2  # SphereMesh height is double radius
```

## Axiom 2.5 — The Mesh in the World

A mesh must be instantiated as a scene object to exist in the world.

Code:

```
var mesh_instance = MeshInstance3D.new()
mesh_instance.mesh = sphere_mesh
mesh_instance.position = Line_position
add_child(mesh_instance)
```

## Axiom 3 — Identity of a Line

The identity of a Line is represented as a **text label** positioned close to the Line.

Code:

```
var label_3d = Label3D.new()
label_3d.text = str(Line_position)
var label_offset = Vector3(0, 0.15, 0)
label_3d.position = Line_position + label_offset
label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
add_child(label_3d)
```

💡 Tip: Always ensure proper null checks and that the node has a valid parent before adding children.