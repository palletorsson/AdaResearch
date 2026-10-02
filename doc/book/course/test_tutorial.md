# A sphere in code

<!-- A simple test tutorial, asked for by Palle on 2 October 2026 ("I want a simple test tutorial")
after the agent-written chapters kept drifting into homemade words. Written by hand, in short-speak and
the tree form, with standard terms. The code was run in Godot 4.6: one child, a MeshInstance3D with a
SphereMesh, at y = 1.0. Not yet reviewed by Palle. -->

*[a white sphere standing one metre above the floor]*

Code can make a body.

1. Open `base.tscn`: double-click it in the FileSystem dock.
2. Add a new script to the root node: right-click it in the Scene dock and choose Attach Script, then Create.
3. Replace the template code with this.

```gdscript
extends Node3D

func _ready():
	var ball := MeshInstance3D.new()
	ball.mesh = SphereMesh.new()
	ball.position = Vector3(0, 1, 0)
	add_child(ball)
```

Run the project: a sphere stands one metre up.

- `MeshInstance3D` is a built-in class: a node that displays a mesh.
  - `.new()` creates an instance of it.
- `SphereMesh` is a built-in class: a sphere-shaped mesh.
  - `ball.mesh = SphereMesh.new()` gives the node its mesh.
- `position` is a property: where the node stands.
  - `Vector3(0, 1, 0)` is one metre up.
- `add_child(ball)` adds `ball` as a child of the root node.
  - Without it, nothing shows.
- Change the `1` to `2`: the sphere stands two metres up.
  - Restore: `Vector3(0, 1, 0)`.

Code makes the body. The editor runs it.
