# The Point
The Atom of Space

A point in 3D space is a vector defining a position (x, y, z).

```
var point_position = Vector3(0, 0, 0)
```

The point is the most fundamental primitive - everything else is built from points.

---

## Visualizing the Point

A visible point can be represented by a small sphere at its designated position.

```
var sphere_mesh = SphereMesh.new()
var radius = 0.01  # one centimeter
sphere_mesh.radius = radius
sphere_mesh.height = radius * 2
```

---

## Instantiating the Point

A mesh must be instantiated into the scene tree to exist in the world.

```
var mesh_instance = MeshInstance3D.new()
mesh_instance.mesh = sphere_mesh
mesh_instance.position = point_position
add_child(mesh_instance)
```

The add_child() call integrates the point into the scene tree, making it part of the rendered world.

---

## Labeling the Point

The identity of a point is represented as a text label close to the point.

```
var label_3d = Label3D.new()
label_3d.text = str(point_position)
var offset = Vector3(0, 0.15, 0)
label_3d.position = point_position + offset
label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
add_child(label_3d)
```

Billboard mode makes the label always face the camera, ensuring readability from any angle.

---

## Dynamic Updates

The text label must update when the point