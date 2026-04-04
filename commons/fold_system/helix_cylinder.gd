# @identity
# essence: vertices on a helix form triangles into a faceted cylinder — pineapple topology
# desire: a closed spiral surface that unfurls from flat triangle grid into a twisted tube
# critical_parameter: fold_amount — 0.0 is flat grid, 1.0 is closed helix cylinder
# triggers: each vertex lerps between grid position and helix position; triangles connect neighbors
# emerges: the spiral seam, the diamond facets, the pineapple pattern — all from sin/cos on a grid
# truth: a cylinder is just a flat grid with its edges identified. the helix adds twist.

class_name HelixCylinder
extends Node3D
## Vertices arranged on a helix, connected as triangles forming a closed
## faceted cylinder. Pineapple/pinecone/Kresling topology.
## Flat at fold_amount=0, closed cylinder at fold_amount=1.

const PrimitiveMeshBuilder: GDScript = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")

const STAGE_COUNT := 5
const STAGE_FOLDS: PackedFloat64Array = [0.0, 0.25, 0.5, 0.75, 1.0]
const SPACING := 0.5

@export var rings: int = 12           ## Rows of vertices along the height
@export var segments_per_ring: int = 8 ## Vertices per ring (around circumference)
@export var radius: float = 0.06      ## Cylinder radius
@export var height: float = 0.25      ## Cylinder height
@export var twist: float = 0.5        ## Helical twist per ring (fraction of full turn)
@export var flat_width: float = 0.35  ## Width of the flat grid
@export var flat_height: float = 0.25 ## Height of the flat grid

var _verts_flat: Array[Vector3] = []
var _verts_helix: Array[Vector3] = []
var _faces: Array = []


func _ready() -> void:
	_generate_geometry()
	_build_stages()


func _generate_geometry() -> void:
	_verts_flat.clear()
	_verts_helix.clear()
	_faces.clear()

	var total_verts: int = rings * segments_per_ring

	for row in rings:
		var row_t: float = float(row) / float(rings - 1)  # 0 to 1 along height

		for col in segments_per_ring:
			var col_t: float = float(col) / float(segments_per_ring)  # 0 to 1 around ring

			# ── Flat position: regular grid on XZ plane ──
			var flat_x: float = (col_t - 0.5) * flat_width
			var flat_z: float = (row_t - 0.5) * flat_height
			_verts_flat.append(Vector3(flat_x, 0.0, flat_z))

			# ── Helix position: point on a twisted cylinder ──
			var angle: float = col_t * TAU + row_t * twist * TAU
			var y: float = (row_t - 0.5) * height
			var hx: float = cos(angle) * radius
			var hz: float = sin(angle) * radius
			_verts_helix.append(Vector3(hx, y, hz))

	# ── Build triangle faces connecting the grid ──
	# Each quad (row,col)→(row,col+1)→(row+1,col+1)→(row+1,col) split into 2 triangles
	for row in (rings - 1):
		for col in segments_per_ring:
			var col_next: int = (col + 1) % segments_per_ring

			var i00: int = row * segments_per_ring + col
			var i01: int = row * segments_per_ring + col_next
			var i10: int = (row + 1) * segments_per_ring + col
			var i11: int = (row + 1) * segments_per_ring + col_next

			# Two triangles per quad — the diamond pattern
			_faces.append([i00, i01, i10])
			_faces.append([i01, i11, i10])


func _build_stages() -> void:
	var total_width: float = (STAGE_COUNT - 1) * SPACING
	var start_x: float = -total_width * 0.5

	for stage in STAGE_COUNT:
		var fold_t: float = STAGE_FOLDS[stage]
		var x_offset: float = start_x + stage * SPACING

		# Interpolate all vertices
		var verts: Array = []
		for i in _verts_flat.size():
			verts.append(_verts_flat[i].lerp(_verts_helix[i], fold_t))

		# Color: teal (flat) → white → warm amber (closed)
		var color: Color
		if fold_t < 0.5:
			var ft: float = fold_t * 2.0
			color = Color(0.3 + ft * 0.5, 0.6 + ft * 0.3, 0.5 + ft * 0.2)
		else:
			var ft: float = (fold_t - 0.5) * 2.0
			color = Color(0.8 + ft * 0.15, 0.75 - ft * 0.25, 0.5 - ft * 0.25)

		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 0.75
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.emission_enabled = true
		mat.emission = color * 0.2
		mat.emission_energy_multiplier = 0.5

		var mesh: ArrayMesh = PrimitiveMeshBuilder.build_mesh(verts, _faces, {"double_sided": true})
		if not mesh:
			continue

		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = mat
		mi.position = Vector3(x_offset, height * 0.5, 0)
		mi.name = "Stage_%d" % stage
		add_child(mi)

		# Label with face/vertex count — proving topology is invariant
		var label := Label3D.new()
		label.text = "%.0f%%\n%dv %df" % [fold_t * 100.0, verts.size(), _faces.size()]
		label.font_size = 42
		label.pixel_size = 0.002
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = Color(color.r, color.g, color.b, 0.9)
		label.position = Vector3(x_offset, -0.06, 0)
		add_child(label)


func apply_grid_config(_config: Dictionary) -> void:
	pass
