## 1.1 Make a sphere

*[a white sphere above the floor; beside it, the code that creates it]*

A node is a building block in Godot.
A scene is a group of nodes.
Code will make the sphere in this scene.

1. Open the [supplied project](/course/sketch/first-sphere.zip) in Godot.
   - Supplied means made for you.
   - The room, camera and lighting are ready.
2. Open `first_sphere.gd` and replace its contents below.
   - A script contains code.
   - This script is attached to the scene's root node.
   - The root node is the scene's top node.

```gdscript
extends Node3D

func _ready():
	var ball = MeshInstance3D.new()
	ball.mesh = SphereMesh.new()
	ball.position = Vector3(0, 1, 0)
	add_child(ball)
```

**Run the project**: press Play, at the top right.
A sphere appears above the floor.

- `extends Node3D` says this script belongs to a `Node3D`.
  - A `Node3D` is a node in 3D space.
- `func` defines a function: a named block of code.
  - Godot runs `_ready()` once the node's children are ready.
  - An indent is spacing that groups code inside a block.
  - Here, one tab groups the code inside `_ready()`.
- `var ball = MeshInstance3D.new()` creates the node.
  - `var` declares a variable: a name for a value.
  - `ball` keeps the node.
  - `=` assigns the value on its right.
  - `MeshInstance3D` is a built-in class: Godot provides it.
  - `.new()` creates one.
- `ball.mesh = SphereMesh.new()` gives it a sphere mesh.
  - The mesh is what the node draws.
  - `mesh` is a property: a named value on the node.
- `ball.position = Vector3(0, 1, 0)` places it.
  - `Vector3` holds three numbers as one value.
  - A position is where a node stands relative to another.
- `add_child(ball)` adds it under the root node.
  - A child is a node directly under another.

1. Change `Vector3(0, 1, 0)` to `Vector3(0, 2, 0)`.
2. Run again: the sphere appears higher.

Create the node, give it a mesh, place it, add it.
