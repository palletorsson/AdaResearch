# Set a position

You already know nodes, scenes, scripts, and `_ready()` from setup.
You can open a project, edit its script, and run it.
Use the supplied project beside this tutorial.
It includes a sphere named `Point`.

*[The same sphere at two heights, labelled y = 1 and y = 2.]*

Nodes can contain other nodes.
The containing node is the parent; those inside are its children.
The root node has no parent within the scene.
Here, `Point` is a child of the scene's root node.

Open `position.gd`, attached to the root node.
Replace its contents with this:

```gdscript
extends Node3D

func _ready():
	$Point.position = Vector3(0, 1, 0)
```

Run the project: the sphere's centre is one metre above the floor.

- The `Node3D` and `_ready()` setup stays the same.
  - The indented line sets the sphere's position when `_ready()` runs.
- Nodes have properties: named values such as `position`.
  - `position` stores a node's position relative to its parent.
- `$Point` gets the child node named `Point`.
  - `$Point.position` accesses that node's `position` property.
- `Vector3` holds three numbers: `x`, `y`, and `z`.
  - Here, they specify the position, in metres.
  - The middle number, `y`, increases upwards.
- `=` assigns the value on the right to the property on the left.

The supplied root node is at the floor's centre.
`Vector3(0, 1, 0)` therefore places the sphere's centre one metre above it.

1. Change `Vector3(0, 1, 0)` to `Vector3(0, 2, 0)`.
2. Run the project again.

The sphere's centre is now two metres above the floor.
Its size stays the same.

Changing `position` changes where the sphere is.
