# @identity
# essence: a triangulated curtain lies pooled on the ground and rises into a hanging drape
# desire: fabric that cascades upward in a wave — each column lifts slightly after the last
# critical_parameter: fold_amount — 0 is pooled flat, 1 is hanging vertical curtain
# triggers: columns cascade left to right with a wave ripple through the fabric
# emerges: the curtain billows as it rises — sine wave adds organic drape to the rigid grid
# truth: a curtain is a floor that remembers it can stand. fold_amount reminds it.

class_name FoldWall
extends Node3D
## A wall that folds up from flat on the ground to vertical.
## Triangulated panels hinge at their base edge, rising in cascade.
## Same vertices, same faces — only positions change.

const PrimitiveMeshBuilder: GDScript = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")

const STAGE_COUNT := 5
const STAGE_FOLDS: PackedFloat64Array = [0.0, 0.25, 0.5, 0.75, 1.0]
const SPACING := 0.6

@export var columns: int = 6          ## Panels across the wall width
@export var rows: int = 4             ## Panels up the wall height
@export var panel_width: float = 0.06 ## Width of each panel
@export var panel_height: float = 0.05 ## Height of each panel
@export var cascade_spread: float = 0.4 ## How much the activation windows spread (0=all at once, 1=full cascade)
@export var drape_amount: float = 0.015 ## Sine wave billow depth (fabric drape)
@export var drape_waves: float = 2.0   ## Number of wave periods across the curtain

var _verts_flat: Array[Vector3] = []
var _verts_wall: Array[Vector3] = []
var _faces: Array = []


func _ready() -> void:
	_generate_geometry()
	_build_stages()


func _generate_geometry() -> void:
	_verts_flat.clear()
	_verts_wall.clear()
	_faces.clear()

	var total_width: float = columns * panel_width
	var total_height: float = rows * panel_height

	# Grid of vertices: (columns+1) x (rows+1)
	for row in (rows + 1):
		var row_t: float = float(row) / float(rows)
		for col in (columns + 1):
			var col_t: float = float(col) / float(columns)

			var x: float = (col_t - 0.5) * total_width

			# ── Flat: everything on the ground (XZ plane) ──
			var flat_z: float = row_t * total_height
			_verts_flat.append(Vector3(x, 0.0, flat_z))

			# ── Wall: bottom row stays on ground, upper rows rise vertically ──
			var wall_y: float = row_t * total_height
			_verts_wall.append(Vector3(x, wall_y, 0.0))

	# Triangulate: two triangles per cell
	var cols_plus := columns + 1
	for row in rows:
		for col in columns:
			var i00: int = row * cols_plus + col
			var i01: int = row * cols_plus + col + 1
			var i10: int = (row + 1) * cols_plus + col
			var i11: int = (row + 1) * cols_plus + col + 1
			_faces.append([i00, i10, i01])
			_faces.append([i01, i10, i11])


func _build_stages() -> void:
	var total_w: float = (STAGE_COUNT - 1) * SPACING
	var start_x: float = -total_w * 0.5

	for stage in STAGE_COUNT:
		var fold_t: float = STAGE_FOLDS[stage]
		var x_off: float = start_x + stage * SPACING

		# For each vertex, compute position based on fold_t
		# Bottom row (row=0) is always on the ground — it's the hinge line
		# Upper rows rotate upward by fold_t * 90 degrees
		# Cascade: columns activate at different times
		var verts: Array = []
		var cols_plus := columns + 1

		for row in (rows + 1):
			var row_t: float = float(row) / float(rows)
			for col in (columns + 1):
				var col_t: float = float(col) / float(columns)
				var idx: int = row * cols_plus + col

				# Cascade activation: each column has a slightly different fold timing
				var col_delay: float = col_t * cascade_spread
				var local_t: float = clamp((fold_t - col_delay) / max(1.0 - cascade_spread, 0.01), 0.0, 1.0)

				# Hinge rotation: bottom edge stays fixed, upper vertices rotate
				# At local_t=0: flat on ground (Z forward)
				# At local_t=1: vertical wall (Y up)
				var hinge_angle: float = local_t * PI * 0.5  # 0 to 90 degrees

				var flat_pos: Vector3 = _verts_flat[idx]
				var base_x: float = flat_pos.x
				var dist_from_base: float = row_t * rows * panel_height

				# Rotate the distance around the X axis (hinge at base)
				var y: float = sin(hinge_angle) * dist_from_base
				var z: float = cos(hinge_angle) * dist_from_base

				# Curtain drape: sine billow increases with height and fold progress
				var drape_z: float = sin(col_t * drape_waves * TAU + row_t * 1.5) * drape_amount * row_t * local_t

				verts.append(Vector3(base_x, y, z + drape_z))

		# Color: stone grey to warm when standing
		var color: Color
		if fold_t < 0.5:
			color = Color(0.55 + fold_t * 0.3, 0.55 + fold_t * 0.2, 0.5 + fold_t * 0.15)
		else:
			var ft: float = (fold_t - 0.5) * 2.0
			color = Color(0.7 + ft * 0.15, 0.65 - ft * 0.05, 0.575 - ft * 0.1)

		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 0.8
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.emission_enabled = true
		mat.emission = color * 0.15
		mat.emission_energy_multiplier = 0.4

		var mesh: ArrayMesh = PrimitiveMeshBuilder.build_mesh(verts, _faces, {"double_sided": true})
		if not mesh:
			continue

		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = mat
		mi.position = Vector3(x_off, 0.0, 0.0)
		add_child(mi)

		var label := Label3D.new()
		label.text = "%.0f%%\n%dv %df" % [fold_t * 100.0, verts.size(), _faces.size()]
		label.font_size = 42
		label.pixel_size = 0.002
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = Color(color.r, color.g, color.b, 0.9)
		label.position = Vector3(x_off, -0.05, 0.15)
		add_child(label)


func apply_grid_config(_config: Dictionary) -> void:
	pass
