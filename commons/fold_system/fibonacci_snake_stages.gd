class_name FibonacciSnakeStages
extends Node3D
## Five stages: Fibonacci spiral → sine snake. Same verts, same faces.

# @identity
# essence: For t in [0..1], lerp(spiral_verts(φ-spiral), snake_verts(sine_wave), t). Five frozen poses share one vertex topology; folding is a parameter, not a transformation of shape.
# desire: To show that "two animals" can be one mesh — a phi-spiral fossil and a sine snake share faces, and the unfold lever is just a number from 0 to 1.
# critical_parameter: STAGE_FOLDS = [0.0, 0.25, 0.5, 0.75, 1.0] sets the snapshots; _segment_count controls resolution; PHI fixes the spiral growth rate.
# triggers: _ready() → _generate_spiral_verts() + _generate_faces() → _build_stages() draws all 5 side-by-side. Static display — no per-frame update.
# emerges: A typology of one — the same skeleton in five poses, making "topology vs morphology" visible without animation.
# needs: VR fold slider [missing], stage-pick controller [missing]
# relationships: Foundation artifact of the fold_system; cousin to deltahedron_stages and helix_fold in Folding_Zoo; the snake-spiral pair anchors the curriculum claim that folding is universal.
# truth: Same vertices, same faces, different shape — folding is a coordinate, not a creature, and the snake was always inside the spiral.

const PrimitiveMeshBuilder: GDScript = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")
const PHI: float = 1.618033988749895
const STAGE_FOLDS: PackedFloat64Array = [0.0, 0.25, 0.5, 0.75, 1.0]
const SPACING := 0.45

var _segment_count: int = 30
var _body_width: float = 0.012
var _spiral_scale: float = 0.006
var _spiral_turns: float = 2.0
var _snake_length: float = 0.3
var _sine_amplitude: float = 0.04
var _sine_frequency: float = 2.5

var _verts_spiral: Array[Vector3] = []
var _faces: Array = []


func _ready() -> void:
	_generate_spiral_verts()
	_generate_faces()
	_build_stages()


func _generate_spiral_verts() -> void:
	for i in (_segment_count + 1):
		var t: float = float(i) / float(_segment_count)
		var angle: float = t * _spiral_turns * TAU
		var r: float = _spiral_scale * pow(PHI, angle / (PI * 0.5))
		var sx: float = cos(angle) * r
		var sz: float = sin(angle) * r
		var ta: float = angle + PI * 0.5
		var px: float = cos(ta) * _body_width
		var pz: float = sin(ta) * _body_width
		_verts_spiral.append(Vector3(sx - px, 0.0, sz - pz))
		_verts_spiral.append(Vector3(sx + px, 0.0, sz + pz))


func _generate_faces() -> void:
	for i in _segment_count:
		var base: int = i * 2
		_faces.append([base, base + 1, base + 2])
		_faces.append([base + 1, base + 3, base + 2])


func _build_stages() -> void:
	var total_w: float = (5 - 1) * SPACING
	var start_x: float = -total_w * 0.5

	for stage in 5:
		var fold_t: float = STAGE_FOLDS[stage]
		var x_off: float = start_x + stage * SPACING

		var verts: Array = []
		for i in (_segment_count + 1):
			var t: float = float(i) / float(_segment_count)
			var snake_z: float = (t - 0.5) * _snake_length
			var snake_x: float = sin(t * _sine_frequency * TAU) * _sine_amplitude * fold_t
			var fwd: Vector2 = Vector2(cos(t * _sine_frequency * TAU) * _sine_frequency * TAU * _sine_amplitude * fold_t, _snake_length).normalized()
			var perp: Vector2 = Vector2(-fwd.y, fwd.x) * _body_width
			var sl := Vector3(snake_x - perp.x, 0.0, snake_z - perp.y)
			var sr := Vector3(snake_x + perp.x, 0.0, snake_z + perp.y)
			var idx: int = i * 2
			verts.append(_verts_spiral[idx].lerp(sl, fold_t))
			verts.append(_verts_spiral[idx + 1].lerp(sr, fold_t))

		# Color: green-gold gradient
		var color: Color
		if fold_t < 0.5:
			color = Color(0.3 + fold_t * 0.4, 0.55 + fold_t * 0.3, 0.25 + fold_t * 0.2)
		else:
			var ft: float = (fold_t - 0.5) * 2.0
			color = Color(0.5 + ft * 0.3, 0.7 - ft * 0.15, 0.35 - ft * 0.15)

		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 0.7
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.emission_enabled = true
		mat.emission = color * 0.25
		mat.emission_energy_multiplier = 0.5

		var mesh: ArrayMesh = PrimitiveMeshBuilder.build_mesh(verts, _faces, {"double_sided": true})
		if not mesh:
			continue

		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = mat
		mi.position = Vector3(x_off, 0.01, 0)
		add_child(mi)

		var label := Label3D.new()
		label.text = "%.0f%%\n%dv %df" % [fold_t * 100.0, verts.size(), _faces.size()]
		label.font_size = 42
		label.pixel_size = 0.002
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = Color(color.r, color.g, color.b, 0.9)
		label.position = Vector3(x_off, -0.1, 0)
		add_child(label)


func apply_grid_config(_config: Dictionary) -> void:
	pass
