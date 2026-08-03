extends "res://algorithms/vectors/shared/vector_scene_base.gd"

# @identity
# essence: a×b = [a.y*b.z - a.z*b.y, a.z*b.x - a.x*b.z, a.x*b.y - a.y*b.x] — a vector perpendicular to both, magnitude |a||b|sin(θ), direction by right-hand rule
# desire: to feel rotation emerge from two directions — the cross product lives in the axis of the rotation that would carry a into b, and the paddle_wheel makes this visceral
# critical_parameter: the right-hand rule — cross product is anti-commutative (a×b = -(b×a)), and the paddle wheel visualizes this as clockwise vs counterclockwise spin
# triggers: vector_a and vector_b positions → cross_vector = a.cross(b) computed each frame → parallelogram mesh spans both vectors → paddle_gadget spins proportional to magnitude
# emerges: the parallelogram area — |a×b| is exactly the area of the parallelogram formed by a and b, making the cross product a measurement of 2D span embedded in 3D
# needs: VR grab to explore plane configurations [missing], paddle wheel interaction [has], parallelogram area display [has], a span axis saying WHAT the area is (tally, face, boundary, number) [has, 2026-07-29], a handedness axis reaching the right-hand rule named above [has, 2026-07-29]. Missing: an in-world switch so a walker can flip handedness without a map edit.
# relationships: complement to VectorDotProduct (dot=cos, cross=sin, both needed for full angle); used in VectorTorque where torque = radius × force
# truth: The cross product does not live in the plane of its inputs — it lives perpendicular to it, measuring how much rotation is implied by two directions.

const PaddleWheelScript = preload("res://algorithms/vectors/shared/gadgets/paddle_wheel_gadget.gd")

# ── DNA (promoted 2026-07-29, stage 2) ───────────────────────────────────────
# span — how |a x b| is shown to BE an area. The magnitude was always drawn as a
# 10x10 lattice of lines across the parallelogram; nothing said that lattice was
# a choice about what area means.
#   grid     the 10x10 ruled lattice — area as a count of cells you could tally.
#            The historical build.
#   solid    one filled translucent quad — area as an undivided region, a face
#            the two vectors close rather than a measure taken of it.
#   outline  the four edges only — area as a bounded shape, the perimeter that
#            two directions imply, with the interior left empty.
#   none     no figure at all. |a x b| survives as a number on the panel and as
#            the length of the purple arrow; the area is asserted, not shown.
@export_enum("grid", "solid", "outline", "none") var span: String = "grid"

# handedness — which order the product is taken in. a x b = -(b x a), and the
# @identity already named the right-hand rule as the critical parameter, but the
# order was welded into _process as a.cross(b).
#   right  a x b (the right-hand rule) — the historical build
#   left   b x a — the same plane, the perpendicular chosen on the other side,
#          and the paddle wheel turning the other way
#   both   both perpendiculars at once, nose to nose through the origin:
#          anti-commutativity as one picture instead of a rule to remember
@export_enum("right", "left", "both") var handedness: String = "right"

var vector_a: Node3D
var vector_b: Node3D
var cross_vector: Node3D
# Only built when handedness == "both"; the default tree is untouched.
var mirror_vector: Node3D = null
var parallelogram: MeshInstance3D
var info_label: Label
var readout_label: Label3D
var magnitude_slider: Node3D
var paddle_gadget: Node3D

# Slider range for |b|.
var _slider_min_mag: float = 0.2
var _slider_max_mag: float = 2.5

# Cached nodes
var _cached_vector_a_nodes: Dictionary = {}
var _cached_vector_b_nodes: Dictionary = {}
var _cached_cross_nodes: Dictionary = {}
var _cached_mirror_nodes: Dictionary = {}

# Throttling
var _time_since_last_text_update: float = 0.0
const TEXT_UPDATE_INTERVAL: float = 0.1

func _ready() -> void:
	super._ready()

func build_scene() -> void:
	# Scaled exhibition presentation (compact at 1.0, walk-inside at 5.0).
	scale = base_scale()
	# rebuild() frees every child, so drop the stale handle before respawning.
	mirror_vector = null
	_cached_mirror_nodes = {}

	create_axes(1.5)
	vector_a = spawn_vector(Vector3.ZERO, Vector3(1.6, 0.2, 1.0), Color(1.0, 0.55, 0.2, 1.0), "Vector a")
	vector_b = spawn_vector(Vector3.ZERO, Vector3(-0.4, 1.5, 0.6), Color(0.2, 0.7, 1.0, 1.0), "Vector b")
	cross_vector = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(0.75, 0.55, 1.0, 1.0), "a x b", false)

	parallelogram = _create_parallelogram_mesh_instance()
	environment_root.add_child(parallelogram)
	info_label = create_info_panel("Cross Product", Vector3(0, 2.5, -0.8), Vector2(2.4, 1.0), "A x B = |A||B|sin(theta) n-hat", "Perpendicular vector, area of parallelogram")

	# Live readout: |a x b| plus the perpendicularity guarantee.
	readout_label = create_readout(Vector3(0.0, 2.0, 0.0), Color(0.8, 0.65, 1.0, 1.0))

	# Paddle wheel gadget
	paddle_gadget = PaddleWheelScript.new()
	paddle_gadget.position = Vector3(-0.6, 0, 0)
	add_child(paddle_gadget)

	# Magnitude slider controlling |b|.
	magnitude_slider = create_magnitude_slider(Vector3(0.0, 0.4, 1.4), "|b|", _slider_min_mag, _slider_max_mag, 0.5)
	if magnitude_slider and magnitude_slider.has_signal("slider_moved"):
		magnitude_slider.connect("slider_moved", Callable(self, "_on_magnitude_slider_moved"))

	# Cache nodes
	_cache_vector_nodes(vector_a, _cached_vector_a_nodes)
	_cache_vector_nodes(vector_b, _cached_vector_b_nodes)
	_cache_vector_nodes(cross_vector, _cached_cross_nodes)

	# DNA — a no-op at handedness=right: no second arrow is built.
	_apply_handedness()

func _on_magnitude_slider_moved(_position) -> void:
	if magnitude_slider == null:
		return
	var norm: float = 0.5
	if magnitude_slider.has_method("get_normalized_value"):
		norm = float(magnitude_slider.call("get_normalized_value"))
	var target_mag: float = lerp(_slider_min_mag, _slider_max_mag, norm)
	var b: Vector3 = _get_vector_fast(vector_b, _cached_vector_b_nodes)
	var dir: Vector3 = b.normalized()
	if dir.length() < 0.001:
		dir = Vector3(0.0, 1.0, 0.0)
	_update_vector_fast(vector_b, dir * target_mag, _cached_vector_b_nodes)

func _process(delta: float) -> void:
	var a = _get_vector_fast(vector_a, _cached_vector_a_nodes)
	var b = _get_vector_fast(vector_b, _cached_vector_b_nodes)
	var cross: Vector3 = a.cross(b)
	if handedness == "left":
		cross = b.cross(a)

	_update_vector_fast(cross_vector, cross, _cached_cross_nodes)
	if mirror_vector != null:
		_update_vector_fast(mirror_vector, -cross, _cached_mirror_nodes)
	_update_parallelogram(a, b)
	if paddle_gadget:
		if handedness == "left":
			paddle_gadget.update_from_vectors(b, a)
		else:
			paddle_gadget.update_from_vectors(a, b)

	_time_since_last_text_update += delta
	if _time_since_last_text_update >= TEXT_UPDATE_INTERVAL:
		_time_since_last_text_update = 0.0
		_update_info(a, b, cross)

func _create_parallelogram_mesh_instance() -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "ParallelogramGrid"

	var array_mesh = ArrayMesh.new()
	mesh_instance.mesh = array_mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.6, 0.85, 1.0, 0.65)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = Color(0.35, 0.55, 0.9)
	material.emission_energy_multiplier = 0.6
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_instance.material_override = material

	return mesh_instance

func _update_parallelogram(a: Vector3, b: Vector3) -> void:
	if parallelogram == null or parallelogram.mesh == null:
		return

	if span == "none":
		parallelogram.visible = false
		return
	parallelogram.visible = true

	var a_s = a * SCENE_SCALE
	var b_s = b * SCENE_SCALE

	var m: ArrayMesh = parallelogram.mesh
	m.clear_surfaces()

	# span = solid — one filled quad, two triangles. The material is already
	# unshaded, alpha 0.65 and cull-disabled, so it reads as a translucent face.
	if span == "solid":
		var quad = PackedVector3Array()
		quad.append(Vector3.ZERO)
		quad.append(a_s)
		quad.append(a_s + b_s)
		quad.append(Vector3.ZERO)
		quad.append(a_s + b_s)
		quad.append(b_s)
		var quad_arrays = []
		quad_arrays.resize(Mesh.ARRAY_MAX)
		quad_arrays[Mesh.ARRAY_VERTEX] = quad
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, quad_arrays)
		return

	var vertices = PackedVector3Array()

	if span == "outline":
		# The four edges only — the boundary two directions imply.
		vertices.append(Vector3.ZERO)
		vertices.append(a_s)
		vertices.append(a_s)
		vertices.append(a_s + b_s)
		vertices.append(a_s + b_s)
		vertices.append(b_s)
		vertices.append(b_s)
		vertices.append(Vector3.ZERO)
	else:
		# span = grid (default) — the historical 10x10 ruled lattice.
		var grid_n := 10  # number of subdivisions per axis

		# Lines along a-direction (from b-axis subdivisions)
		for i in range(grid_n + 1):
			var t = float(i) / float(grid_n)
			var start = b_s * t
			var end_pt = a_s + b_s * t
			vertices.append(start)
			vertices.append(end_pt)

		# Lines along b-direction (from a-axis subdivisions)
		for i in range(grid_n + 1):
			var t = float(i) / float(grid_n)
			var start = a_s * t
			var end_pt = a_s * t + b_s
			vertices.append(start)
			vertices.append(end_pt)

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices

	if vertices.size() >= 2:
		m.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)

# ── DNA helpers ──────────────────────────────────────────────────────────────

## The opposite perpendicular exists only for handedness == "both", so no
## shipped placement ever gains a node it did not have.
func _ensure_mirror_vector() -> void:
	if mirror_vector != null:
		return
	mirror_vector = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(0.4, 0.9, 0.75, 0.85), "b x a", false)
	_cache_vector_nodes(mirror_vector, _cached_mirror_nodes)

func _apply_handedness() -> void:
	if handedness == "both":
		_ensure_mirror_vector()
	if mirror_vector != null:
		mirror_vector.visible = (handedness == "both")

## Extends the base (which owns scale_multiplier / laser_endpoints and may call
## rebuild()). The axes are set BEFORE the super call so that if the base does
## rebuild, build_scene() already sees the new values. Both axes are otherwise
## applied live — no rebuild is triggered by the axes themselves, and an absent
## or unknown key leaves the artifact exactly as built.
func apply_grid_config(config: Dictionary) -> void:
	if config == null or config.is_empty():
		return
	var hand_changed: bool = false
	if config.has("span"):
		var s: String = str(config["span"])
		if s in ["grid", "solid", "outline", "none"]:
			span = s  # read per frame in _update_parallelogram; no rebuild
	if config.has("handedness"):
		var h: String = str(config["handedness"])
		if h in ["right", "left", "both"] and h != handedness:
			handedness = h
			hand_changed = true
	super.apply_grid_config(config)
	# Only act once the scene has actually been built.
	if hand_changed and _scene_built:
		_apply_handedness()

func _update_info(a: Vector3, b: Vector3, cross: Vector3) -> void:
	var mag_a = a.length()
	var mag_b = b.length()
	var dot = a.dot(b)
	var angle = 0.0
	if mag_a > 0.0001 and mag_b > 0.0001:
		angle = acos(clamp(dot / (mag_a * mag_b), -1.0, 1.0))
	var area = cross.length()
	var product_name: String = "a x b"
	if handedness == "left":
		product_name = "b x a"
	var builder := []
	builder.append("a = (%.2f, %.2f, %.2f)" % [a.x, a.y, a.z])
	builder.append("b = (%.2f, %.2f, %.2f)" % [b.x, b.y, b.z])
	builder.append("%s = (%.2f, %.2f, %.2f)" % [product_name, cross.x, cross.y, cross.z])
	builder.append("|%s| (area) = %.2f" % [product_name, area])
	builder.append("angle ~= %.1f deg" % rad_to_deg(angle))
	if mag_a > 0.0001 and mag_b > 0.0001:
		var sine = area / (mag_a * mag_b)
		builder.append("sin(angle) ~= %.2f" % clamp(sine, -1.0, 1.0))
	info_label.text = "\n".join(builder)
	if readout_label:
		# Confirm perpendicularity numerically (dot of cross with each input ~0).
		var perp_a: float = absf(cross.dot(a))
		var perp_b: float = absf(cross.dot(b))
		var perp_ok: bool = perp_a < 0.01 and perp_b < 0.01
		var perp_text: String = "perp to a and b" if perp_ok else "perp to a and b (~0)"
		readout_label.text = "|a x b| = %.2f\n%s" % [area, perp_text]

# --- Caching Helpers (Local Implementation) ---

func _cache_vector_nodes(arrow: Node3D, cache_dict: Dictionary) -> void:
	if arrow == null: return
	cache_dict["start"] = arrow.get_node_or_null("lineContainer/GrabSphere")
	cache_dict["end"] = arrow.get_node_or_null("lineContainer/GrabSphere2")
	cache_dict["line_container"] = arrow.get_node_or_null("lineContainer")

func _get_vector_fast(arrow: Node3D, cache_dict: Dictionary) -> Vector3:
	var start: Node3D = cache_dict.get("start")
	var end: Node3D = cache_dict.get("end")
	if start and end:
		# SCENE_SCALE division handled here to return logical vector
		return (end.global_position - start.global_position) / (SCENE_SCALE * scale.x)
	if arrow.has_method("get_vector"):
		return arrow.get_vector()
	return Vector3.ZERO

func _update_vector_fast(_arrow: Node3D, vector: Vector3, cache_dict: Dictionary) -> void:
	var end_node: Node3D = cache_dict.get("end")
	if end_node:
		# SCENE_SCALE multiplication handled here for visual representation
		end_node.position = vector * SCENE_SCALE
	var line_container: Node3D = cache_dict.get("line_container")
	if line_container and line_container.has_method("refresh_connections"):
		line_container.refresh_connections()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
