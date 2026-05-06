# The Point
The atom of space

A point is the smallest unit of computational geometry.

In three-dimensional space, a point **is a position**, defined by three numbers:
**x, y, and z**.

A point has:
• no size
• no shape
• no direction

It is defined only by where it is.

---

## Position in the engine

In a game engine like Godot, every point always has a position.
The engine stores this position continuously as a vector.

Code

```
var point_position = Vector3(3.0, 1.5, 4.0)
```

This vector is the point.

---

## Making a point visible

To see a point, we represent it with a small sphere.
The sphere is not the point — it is a visual marker for a position.

Code

```
var sphere_mesh = SphereMesh.new()
var radius = 0.01
sphere_mesh.radius = radius
sphere_mesh.height = radius * 2.0
```

---

## Placing the point

The marker is placed at the point’s coordinates.

Code

```
var mesh_instance = MeshInstance3D.new()
mesh_instance.mesh = sphere_mesh
mesh_instance.position = point_position
add_child(mesh_instance)
```

The scene now shows **where** the point is.

Nothing has been added to the point itself.
Only its position has been made visible.

---

## What comes next

The point already has a position.
The next step is not to give it one.

The next step is to make the position readable and comparable.

---