@tool
extends "res://commons/primitives/cubes/grab_cube_scalable.gd"

## Snappable Grab Cube
##
## Extends scalable grab cube with grid-based face snapping.
## When faces of two cubes are close and parallel, they snap to
## align on a 0.05m grid. Simpler and more flexible than attachment points.

const FaceSnapSystemScript = preload("res://commons/primitives/furniture/face_snap_system.gd")

## Enable face snapping
@export var enable_face_snapping: bool = true

## Show grid overlay when faces are near
@export var show_snap_grid: bool = true

## Signal when snapped to another cube
signal cube_snapped(other_cube: Node3D, my_face: int, other_face: int)

## Signal when unsnapped
signal cube_unsnapped(other_cube: Node3D)

# Face snap system instance
var _face_snap_system: Node = null


func _ready() -> void:
	super()

	if not Engine.is_editor_hint():
		# Add to group for identification
		add_to_group("snappable_cubes")

		if enable_face_snapping:
			_setup_face_snap_system()


func _setup_face_snap_system() -> void:
	print("GrabCubeSnappable: Setting up face snap system for %s" % name)
	_face_snap_system = FaceSnapSystemScript.new()
	_face_snap_system.name = "FaceSnapSystem"
	_face_snap_system.show_grid_overlay = show_snap_grid
	add_child(_face_snap_system)

	# Connect signals
	_face_snap_system.face_snapped.connect(_on_face_snapped)
	_face_snap_system.face_unsnapped.connect(_on_face_unsnapped)

	print("GrabCubeSnappable: Face snap system initialized for %s, child count: %d" % [name, get_child_count()])


func _on_face_snapped(other_cube: Node3D, my_face: int, other_face: int) -> void:
	cube_snapped.emit(other_cube, my_face, other_face)


func _on_face_unsnapped(other_cube: Node3D) -> void:
	cube_unsnapped.emit(other_cube)


## Check if currently snapped to another cube
func is_snapped() -> bool:
	if _face_snap_system and _face_snap_system.has_method("is_snapped"):
		return _face_snap_system.is_snapped()
	return false


## Get the cube we're snapped to
func get_snapped_cube() -> Node3D:
	if _face_snap_system and _face_snap_system.has_method("get_snapped_cube"):
		return _face_snap_system.get_snapped_cube()
	return null


## Get all cubes connected to this one via physics joints
## Uses breadth-first search through joint connections
func get_attached_cubes() -> Array[Node3D]:
	var attached: Array[Node3D] = []
	var visited: Dictionary = {self: true}
	var queue: Array[Node3D] = [self]

	while not queue.is_empty():
		var current = queue.pop_front()
		# Find all joints on this cube
		for child in current.get_children():
			if child is Generic6DOFJoint3D:
				var joint = child as Generic6DOFJoint3D
				# Get the other cube connected by this joint
				var node_a = current.get_node_or_null(joint.node_a)
				var node_b = current.get_node_or_null(joint.node_b)
				for other in [node_a, node_b]:
					if other and other != current and other not in visited:
						if other.is_in_group("snappable_cubes"):
							attached.append(other)
							visited[other] = true
							queue.append(other)

		# Also check if other cubes have joints pointing to us
		for cube in get_tree().get_nodes_in_group("snappable_cubes"):
			if cube in visited:
				continue
			for child in cube.get_children():
				if child is Generic6DOFJoint3D:
					var joint = child as Generic6DOFJoint3D
					var node_a = cube.get_node_or_null(joint.node_a)
					var node_b = cube.get_node_or_null(joint.node_b)
					if node_a == current or node_b == current:
						attached.append(cube)
						visited[cube] = true
						queue.append(cube)
						break

	return attached


## Check if this cube has any attached cubes
func has_attached_cubes() -> bool:
	# Check if we have any joints
	for child in get_children():
		if child is Generic6DOFJoint3D:
			return true
	# Check if any other cube has a joint to us
	for cube in get_tree().get_nodes_in_group("snappable_cubes"):
		if cube == self:
			continue
		for child in cube.get_children():
			if child is Generic6DOFJoint3D:
				var joint = child as Generic6DOFJoint3D
				var node_a = cube.get_node_or_null(joint.node_a)
				var node_b = cube.get_node_or_null(joint.node_b)
				if node_a == self or node_b == self:
					return true
	return false


## Get all cubes in this assembly (including self)
func get_assembly() -> Array[Node3D]:
	var assembly = get_attached_cubes()
	assembly.insert(0, self)
	return assembly
