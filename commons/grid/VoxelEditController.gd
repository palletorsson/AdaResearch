# VoxelEditController.gd — Shared raycast → grid → edit logic
#
# Handles the core Minecraft-style voxel editing: raycast from camera (or VR
# controller), detect which cube face is hit, show ghost preview, add/remove
# cubes. Used by both desktop and VR builders.
#
# Usage:
#   var edit := VoxelEditController.new()
#   edit.structure_component = my_grid_structure
#   add_child(edit)
#   # Each frame: edit updates ghost cube position
#   # On click: edit.try_add() or edit.try_remove()

class_name VoxelEditController
extends Node3D


# ─────────────────────────────────────────────────────────────
#  References
# ─────────────────────────────────────────────────────────────

## The grid structure component to edit.
var structure_component: GridStructureComponent = null

## Cube size (must match grid).
var cube_size: float = 1.0


# ─────────────────────────────────────────────────────────────
#  State
# ─────────────────────────────────────────────────────────────

## Current targeted grid cell (the cube being looked at).
var target_cell: Vector3i = Vector3i(-1, -1, -1)

## Position where a new cube would be added (face-adjacent to target).
var add_cell: Vector3i = Vector3i(-1, -1, -1)

## The face normal of the hit.
var hit_normal: Vector3 = Vector3.ZERO

## Whether we have a valid target.
var has_target: bool = false

## Ghost cube preview meshes — green for add, red for remove.
var _ghost_add: MeshInstance3D = null
var _ghost_remove: MeshInstance3D = null

## Undo/redo stacks.
var _undo_stack: Array[Dictionary] = []
var _redo_stack: Array[Dictionary] = []
var _max_undo: int = 100


# ─────────────────────────────────────────────────────────────
#  Signals
# ─────────────────────────────────────────────────────────────

signal cube_added(pos: Vector3i)
signal cube_removed(pos: Vector3i)


# ═══════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════

func _ready() -> void:
	_create_ghost_cubes()


# ═══════════════════════════════════════════════════════════════
# RAYCAST — Call each frame with ray origin + direction
# ═══════════════════════════════════════════════════════════════

## Update target from a ray (desktop: from camera, VR: from controller).
func update_target_from_ray(ray_origin: Vector3, ray_dir: Vector3, max_dist: float = 50.0) -> void:
	has_target = false
	target_cell = Vector3i(-1, -1, -1)
	add_cell = Vector3i(-1, -1, -1)

	var space := get_world_3d().direct_space_state
	if not space:
		_update_ghost()
		return

	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_dir * max_dist)
	var result := space.intersect_ray(query)

	if result.is_empty():
		_update_ghost()
		return

	var hit_pos: Vector3 = result.position
	hit_normal = result.normal

	# Convert hit position to grid coordinates
	# Offset slightly inward along normal to get the cube we hit (not the adjacent one)
	var inward: Vector3 = hit_pos - hit_normal * 0.01
	target_cell = _world_to_grid(inward)

	# The add position is on the face — offset outward along normal
	var outward: Vector3 = hit_pos + hit_normal * 0.01
	add_cell = _world_to_grid(outward)

	has_target = true
	_update_ghost()


## Update target from mouse position (desktop convenience).
func update_target_from_mouse() -> void:
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return
	var mouse_pos := get_viewport().get_mouse_position()
	var origin := camera.project_ray_origin(mouse_pos)
	var dir := camera.project_ray_normal(mouse_pos)
	update_target_from_ray(origin, dir)


# ═══════════════════════════════════════════════════════════════
# EDITING
# ═══════════════════════════════════════════════════════════════

## Try to add a cube at the current add_cell position.
func try_add() -> bool:
	if not has_target or not structure_component:
		return false

	var x: int = add_cell.x
	var z: int = add_cell.z

	# Get current height and check if we're adding on top
	var current_height: int = structure_component.get_height_at(x, z)

	# Record for undo
	_push_undo(x, z, current_height, current_height + 1)

	if structure_component.stack_add(x, z):
		cube_added.emit(add_cell)
		return true
	else:
		_undo_stack.pop_back()  # Remove failed undo entry
		return false


## Try to remove the cube at the current target_cell position.
func try_remove() -> bool:
	if not has_target or not structure_component:
		return false

	var x: int = target_cell.x
	var z: int = target_cell.z

	var current_height: int = structure_component.get_height_at(x, z)

	_push_undo(x, z, current_height, current_height - 1)

	if structure_component.stack_remove(x, z):
		cube_removed.emit(target_cell)
		return true
	else:
		_undo_stack.pop_back()
		return false


## Undo last action.
func undo() -> bool:
	if _undo_stack.is_empty() or not structure_component:
		return false

	var entry: Dictionary = _undo_stack.pop_back()
	structure_component.set_height_at(entry["x"], entry["z"], entry["old_height"])
	_redo_stack.append(entry)
	return true


## Redo last undone action.
func redo() -> bool:
	if _redo_stack.is_empty() or not structure_component:
		return false

	var entry: Dictionary = _redo_stack.pop_back()
	structure_component.set_height_at(entry["x"], entry["z"], entry["new_height"])
	_undo_stack.append(entry)
	return true


# ═══════════════════════════════════════════════════════════════
# GHOST CUBE — Translucent preview
# ═══════════════════════════════════════════════════════════════

func _create_ghost_cubes() -> void:
	# Ghosts are added to the SCENE ROOT (not as children of this node)
	# because this node may be deep inside a scaled-down catalyst.
	# They use global_position so they appear at world-scale grid cells.
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3.ONE * cube_size * 0.98

	# Green ghost — shows where a cube will be ADDED
	_ghost_add = MeshInstance3D.new()
	_ghost_add.name = "GhostAdd"
	_ghost_add.mesh = box_mesh
	_ghost_add.top_level = true  # Ignore parent transform — render at world scale
	var add_mat := StandardMaterial3D.new()
	add_mat.albedo_color = Color(0.2, 0.9, 0.3, 0.35)
	add_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	add_mat.no_depth_test = true
	add_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ghost_add.material_override = add_mat
	_ghost_add.visible = false
	add_child(_ghost_add)

	# Red ghost — shows which cube will be REMOVED
	_ghost_remove = MeshInstance3D.new()
	_ghost_remove.name = "GhostRemove"
	_ghost_remove.mesh = box_mesh.duplicate()
	_ghost_remove.top_level = true  # Ignore parent transform — render at world scale
	var rem_mat := StandardMaterial3D.new()
	rem_mat.albedo_color = Color(0.9, 0.2, 0.2, 0.25)
	rem_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rem_mat.no_depth_test = true
	rem_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ghost_remove.material_override = rem_mat
	_ghost_remove.visible = false
	add_child(_ghost_remove)


func _update_ghost() -> void:
	if not has_target or not structure_component:
		if _ghost_add: _ghost_add.visible = false
		if _ghost_remove: _ghost_remove.visible = false
		return

	var total_size: float = cube_size + (structure_component.gutter if structure_component else 0.0)

	# Green ghost at the ADD position (face-adjacent empty cell)
	if _ghost_add:
		_ghost_add.visible = true
		_ghost_add.global_position = Vector3(
			float(add_cell.x) * total_size,
			float(add_cell.y) * total_size,
			float(add_cell.z) * total_size
		)

	# Red ghost on the REMOVE target (the existing cube being aimed at)
	if _ghost_remove:
		_ghost_remove.visible = true
		_ghost_remove.global_position = Vector3(
			float(target_cell.x) * total_size,
			float(target_cell.y) * total_size,
			float(target_cell.z) * total_size
		)


# ═══════════════════════════════════════════════════════════════
# INTERNAL
# ═══════════════════════════════════════════════════════════════

func _world_to_grid(world_pos: Vector3) -> Vector3i:
	var total_size: float = cube_size
	if structure_component:
		total_size = cube_size + structure_component.gutter
	return Vector3i(
		int(floor(world_pos.x / total_size)),
		int(floor(world_pos.y / total_size)),
		int(floor(world_pos.z / total_size))
	)


func _push_undo(x: int, z: int, old_h: int, new_h: int) -> void:
	_undo_stack.append({"x": x, "z": z, "old_height": old_h, "new_height": new_h})
	if _undo_stack.size() > _max_undo:
		_undo_stack.pop_front()
	_redo_stack.clear()  # New action invalidates redo
