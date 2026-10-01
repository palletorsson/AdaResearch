extends Node3D
## Supplied lattice. One contract: carve(at) -> int.
## `at` is a position in the room: a global position. A body stands there. Every
## cell within `bite` of it, measured along the floor, is removed with its
## collider, and the call returns how many cells that removed. The body is taller
## than the lattice, so its height does not count. Removed cells stay removed:
## the lattice keeps the cut. The label counts what is left; `lost` lists what went.
## fill() builds the lattice again, whole.
## The cells are made by two loops, one inside the other, and a node made in code
## for every cell. The chessboard chapter opens both.

@export var columns := 8
@export var rows := 11
@export var spacing := 0.12   # metres from the middle of one cell to the next
@export var cell := 0.1       # metres: the edge of one cell
@export var bite := 0.16      # metres: how far from `at` a cell is taken

var cells := {}                  # Vector2i(column, row) -> [the cell's mesh node, its collision shape]
var lost: Array[Vector2i] = []   # the cells removed so far, in the order they went

var _body: StaticBody3D
var _mesh: BoxMesh
var _shape: BoxShape3D

func _ready() -> void:
	_mesh = BoxMesh.new()
	_mesh.size = Vector3(cell, cell, cell)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.16, 0.3, 0.42)
	material.roughness = 0.9
	_mesh.material = material
	_shape = BoxShape3D.new()
	_shape.size = _mesh.size
	_body = StaticBody3D.new()
	_body.name = "Body"
	add_child(_body)
	fill()

func fill() -> void:
	for pair: Array in cells.values():
		pair[0].free()
		pair[1].free()
	cells.clear()
	lost.clear()
	for column in columns:
		for row in rows:
			var at := Vector3(column * spacing, 0.0, row * spacing)
			var box := MeshInstance3D.new()
			box.mesh = _mesh
			box.position = at
			add_child(box)
			var shape := CollisionShape3D.new()
			shape.shape = _shape
			shape.position = at
			_body.add_child(shape)
			cells[Vector2i(column, row)] = [box, shape]
	_count()

func carve(at: Vector3) -> int:
	var here := to_local(at)
	var removed := 0
	for key: Vector2i in cells.keys():
		var across := Vector2(key.x * spacing - here.x, key.y * spacing - here.z)
		if across.length() <= bite:
			cells[key][0].free()
			cells[key][1].free()
			cells.erase(key)
			lost.append(key)
			removed += 1
	if removed > 0:
		_count()
	return removed

func _count() -> void:
	if has_node("Count"):
		$Count.text = "%d of %d cells" % [cells.size(), columns * rows]
