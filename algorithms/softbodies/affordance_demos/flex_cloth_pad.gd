# Flex Cloth Pad — the `flex` / `drape` catalyst affordance for softbodies
#
# A small platform holds a hanging cloth pad: a grid of cloth vertices simulated as a
# spring-mass system. The pad sways gently. The catalyst's flex/drape mode lets the
# player nudge the cloth in real time — pressing the trigger applies an impulse to the
# nearest vertex, and the cloth ripples in response.
#
# Demonstrates that the bracelet at integration is no longer just a placer or stamper —
# it interacts with continuous matter. Cloth is the test case because it's the simplest
# soft body the player has met.
#
# @identity: First map where the player meets a *deformable* catalyst affordance.
# @qfep_term: Integration (system settling under perturbation).

extends Node3D
class_name FlexClothPad

@export_category("Cloth Settings")
@export var cloth_color: Color = Color(0.7, 0.85, 0.95, 1.0)
@export var anchor_color: Color = Color(0.4, 0.45, 0.55, 1.0)
@export var grid_cols: int = 8
@export var grid_rows: int = 10
@export var cloth_width: float = 0.9
@export var cloth_height: float = 1.1
@export var stiffness: float = 35.0
@export var damping: float = 1.5
@export var gravity: float = 3.5

var _verts: Array = []        # current positions
var _vels: Array = []         # velocities
var _rest_pos: Array = []     # rest positions for return spring
var _cloth_mesh: MeshInstance3D
var _pedestal: MeshInstance3D
var _t: float = 0.0


func _ready() -> void:
	_build_pedestal()
	_init_cloth()
	_build_cloth_mesh()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("grid_cols"):
		grid_cols = int(config_data["grid_cols"])
	if config_data.has("grid_rows"):
		grid_rows = int(config_data["grid_rows"])


func _process(delta: float) -> void:
	_t += delta
	_step_cloth(delta)
	# Sway: nudge the bottom row periodically to simulate breeze + idle motion.
	var sway: float = sin(_t * 1.4) * 0.04
	for j in grid_cols:
		var idx: int = (grid_rows - 1) * grid_cols + j
		_vels[idx].x += sway * delta
	_rebuild_cloth_mesh()


func _build_pedestal() -> void:
	_pedestal = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.4
	cyl.bottom_radius = 0.45
	cyl.height = 0.7
	_pedestal.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = anchor_color
	mat.roughness = 0.85
	_pedestal.material_override = mat
	_pedestal.position.y = 0.35
	add_child(_pedestal)


func _init_cloth() -> void:
	# Cloth hangs from the top, pinned to the pedestal top center.
	var top_y: float = 1.9
	for i in grid_rows:
		for j in grid_cols:
			var u: float = float(j) / float(grid_cols - 1) - 0.5
			var v: float = float(i) / float(grid_rows - 1)
			var pos := Vector3(u * cloth_width, top_y - v * cloth_height, 0.0)
			_verts.append(pos)
			_rest_pos.append(pos)
			_vels.append(Vector3.ZERO)


func _build_cloth_mesh() -> void:
	_cloth_mesh = MeshInstance3D.new()
	_cloth_mesh.name = "Cloth"
	add_child(_cloth_mesh)
	_rebuild_cloth_mesh()


func _rebuild_cloth_mesh() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in grid_rows - 1:
		for j in grid_cols - 1:
			var v00: Vector3 = _verts[i * grid_cols + j]
			var v10: Vector3 = _verts[i * grid_cols + j + 1]
			var v01: Vector3 = _verts[(i + 1) * grid_cols + j]
			var v11: Vector3 = _verts[(i + 1) * grid_cols + j + 1]
			st.add_vertex(v00); st.add_vertex(v10); st.add_vertex(v11)
			st.add_vertex(v00); st.add_vertex(v11); st.add_vertex(v01)
	st.generate_normals()
	_cloth_mesh.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = cloth_color
	mat.roughness = 0.55
	mat.metallic = 0.05
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_cloth_mesh.material_override = mat


func _step_cloth(delta: float) -> void:
	# Simple per-vertex spring-toward-rest with gravity and damping.
	# (A real cloth would have edge springs between vertices; this is a starter scaffold.)
	for i in _verts.size():
		# Skip the top row — pinned.
		if i < grid_cols:
			continue
		var rest_p: Vector3 = _rest_pos[i]
		var cur_p: Vector3 = _verts[i]
		var to_rest: Vector3 = rest_p - cur_p
		var accel: Vector3 = to_rest * stiffness
		accel.y -= gravity
		var v: Vector3 = _vels[i]
		v = v + accel * delta
		v *= 1.0 - damping * delta
		_vels[i] = v
		_verts[i] = cur_p + v * delta
