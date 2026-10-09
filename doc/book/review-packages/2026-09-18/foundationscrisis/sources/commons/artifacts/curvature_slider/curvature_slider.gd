# curvature_slider.gd
# Slider controlling curvature: negative (hyperbolic) ↔ zero (flat) ↔ positive (elliptic)

extends Node3D
class_name CurvatureSlider

# @identity
# essence: K ∈ [-1, +1] — Gaussian curvature as continuous parameter
# desire: slide between hyperbolic, flat, and elliptic geometry with one hand
# critical_parameter: curvature — the ONE number that determines the entire geometry
# triggers: slider movement emits curvature_changed signal, updates label with geometry type
# emerges: the intuition that geometry is not fixed — it is a parameter you can vary
# needs: VR horizontal slider [has]
# relationships: controls hyperbolic_surface (K<0) and elliptic_surface (K>0); depends on euclid_postulates_plaque (the fifth postulate IS the curvature assumption)
# truth: flat space is not the default — it is the singular boundary between two infinite families of geometries

## ─── STAGE-2 DNA (promoted 2026-08-05) ────────────────────────────────────────
##
##  opening  — which of the three signs the bench is PARKED at when you walk up.
##             dot_aligner's word, taken because this is dot_aligner's situation
##             exactly: a set of named cases that existed only behind a hand in a
##             headset, with `curvature` exported, never read at build time and
##             therefore unreachable from any map token. Its value list
##             (agreeing|strangers|opposing|parallel) is REFUSED — those name four
##             angles between two vectors, and the classification here has exactly
##             three members, because the sign of K has exactly three values.
##             Adding a fourth would invent a geometry.
##  witness  — what the instrument shows you of the geometry it names: the claim,
##             the object, or the mechanism. Before this pass a curvature slider
##             displayed no curvature at all — a number and the word for it — so
##             every value of `opening` would have differed by two lines of text.
##             `surface` builds the patch K describes (saddle · plane · dome) and
##             `normals` adds the Gauss map, the normal field whose turning IS the
##             definition of K: splayed on the dome, parallel on the plane,
##             anticlastic on the saddle.
##
##  DECLINED, and measured before declining: a geodesic-triangle value showing the
##  angle sum (<180 · =180 · >180), the classical still-visible test of K's sign.
##  A straight chord in the patch's parameter plane lifted onto the surface is NOT
##  a geodesic, and the lifted-chord angle sum comes out 179.6° on the saddle and
##  161.1° on the DOME — the wrong side of 180 for positive curvature, stable
##  across every rotation of the triangle. Shipping it would have published a
##  finished-looking figure that states the theorem backwards. Real geodesics on a
##  paraboloid need an integrator, which is a different piece of work.
## ──────────────────────────────────────────────────────────────────────────────

signal curvature_changed(value: float)

const OPENINGS := {"hyperbolic": -1.0, "flat": 0.0, "elliptic": 1.0}
const WITNESSES := ["number", "surface", "normals"]

const PATCH_SIZE := 0.16      # metres across, matched to the rack panel's width
const PATCH_Y := 0.30         # above the label, which sits at 0.18
const PATCH_BOW := 0.05       # centre rise at |K| = 1
const PATCH_N := 14           # grid divisions per side
const PIN_N := 5              # normal pins per side
const PIN_LEN := 0.035

@export_enum("flat", "hyperbolic", "elliptic") var opening: String = "flat"
@export_enum("number", "surface", "normals") var witness: String = "number"

@export var curvature: float = 0.0  # -1 to +1

var _slider: Node
var _label: Label3D
var _indicator: MeshInstance3D
var _specimen: Node3D
var _built: bool = false

func _ready():
	curvature = _k()
	_create_controls()
	_create_label()
	_create_specimen()
	_built = true

# The K this placement opens at. "flat" SHORT-CIRCUITS and hands back the shipped
# `curvature` export verbatim rather than the table's 0.0, so a map that overrides
# curvature alone still opens at its own number instead of being reset to zero.
func _k() -> float:
	if opening == "flat" or not OPENINGS.has(opening):
		return curvature
	return float(OPENINGS[opening])

func _create_controls():
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	# The knob starts where K says it should. At the shipped K = 0 this is 0.5, the
	# literal that was here before, so the panel is built identically.
	var knob: float = clampf((curvature + 1.0) * 0.5, 0.0, 1.0)
	var panel: Node3D = RackTpl.create_parameter_panel(1, ["CURVATURE K"], [knob])
	add_child(panel)
	_slider = panel.get_node_or_null("Param_0")
	if _slider and _slider.has_signal("slider_moved"):
		_slider.slider_moved.connect(_on_slider_moved)

func _create_label():
	_label = Label3D.new()
	_label.pixel_size = 0.001
	_label.font_size = 14
	_label.text = _label_text()
	_label.position = Vector3(0, 0.18, 0)
	_label.modulate = Color(0.1, 0.1, 0.1)
	add_child(_label)

func _on_slider_moved(_pos):
	if _slider and _slider.has_method("get_normalized_value"):
		curvature = _slider.get_normalized_value() * 2.0 - 1.0  # Map 0-1 to -1 to +1
		_update_label()
		_rebuild_specimen()
		curvature_changed.emit(curvature)

# "0" and not "0.00": the string the flat default has always carried, kept to the
# byte so the 5 existing placements read exactly as they did.
func _k_str(k: float) -> String:
	return "0" if is_zero_approx(k) else "%.2f" % k

func _label_text() -> String:
	var type_str = "Flat/Euclidean"
	if curvature < -0.1:
		type_str = "Hyperbolic"
	elif curvature > 0.1:
		type_str = "Elliptic"
	return "CURVATURE: K = %s\n(%s)" % [_k_str(curvature), type_str]

func _update_label():
	_label.text = _label_text()


# ─── the specimen: the surface K describes ────────────────────────────────────
# Built ONLY when witness names it. At the shipped "number" this function adds no
# node at all, so the scene tree is the panel and the label and nothing else.

func _create_specimen() -> void:
	if witness == "number":
		return
	_specimen = Node3D.new()
	_specimen.name = "Specimen"
	_specimen.position = Vector3(0, PATCH_Y, 0)
	add_child(_specimen)
	_specimen.add_child(_build_patch(curvature))
	if witness == "normals":
		_add_normal_pins(_specimen, curvature)

func _rebuild_specimen() -> void:
	if _specimen == null or not is_instance_valid(_specimen):
		return
	for c in _specimen.get_children():
		_specimen.remove_child(c)
		c.queue_free()
	_specimen.add_child(_build_patch(curvature))
	if witness == "normals":
		_add_normal_pins(_specimen, curvature)

# Height over the unit square (nx, nz) ∈ [-1, 1]².
#   K > 0 — an elliptic paraboloid, positively curved at every point
#   K = 0 — the plane, the singular boundary between the two families
#   K < 0 — a hyperbolic paraboloid, negatively curved at every point
func _patch_height(k: float, nx: float, nz: float) -> float:
	var t: float = absf(k)
	if t < 0.005:
		return 0.0
	if k > 0.0:
		return PATCH_BOW * t * (1.0 - nx * nx - nz * nz)
	return PATCH_BOW * t * (nx * nx - nz * nz)

# Central difference rather than the analytic gradient: two height branches, two
# chances to write a sign backwards, and the pins are the whole evidence here.
func _patch_normal(k: float, nx: float, nz: float) -> Vector3:
	var half: float = PATCH_SIZE * 0.5
	var e: float = 0.02
	var hx: float = (_patch_height(k, nx + e, nz) - _patch_height(k, nx - e, nz)) / (2.0 * e * half)
	var hz: float = (_patch_height(k, nx, nz + e) - _patch_height(k, nx, nz - e)) / (2.0 * e * half)
	return Vector3(-hx, 1.0, -hz).normalized()

func _build_patch(k: float) -> MeshInstance3D:
	var half: float = PATCH_SIZE * 0.5
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(PATCH_N):
		for j in range(PATCH_N):
			var u0: float = -1.0 + 2.0 * float(i) / float(PATCH_N)
			var u1: float = -1.0 + 2.0 * float(i + 1) / float(PATCH_N)
			var v0: float = -1.0 + 2.0 * float(j) / float(PATCH_N)
			var v1: float = -1.0 + 2.0 * float(j + 1) / float(PATCH_N)
			var a: Vector3 = Vector3(u0 * half, _patch_height(k, u0, v0), v0 * half)
			var b: Vector3 = Vector3(u1 * half, _patch_height(k, u1, v0), v0 * half)
			var c: Vector3 = Vector3(u1 * half, _patch_height(k, u1, v1), v1 * half)
			var d: Vector3 = Vector3(u0 * half, _patch_height(k, u0, v1), v1 * half)
			st.add_vertex(a)
			st.add_vertex(b)
			st.add_vertex(c)
			st.add_vertex(a)
			st.add_vertex(c)
			st.add_vertex(d)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = "Patch"
	mi.mesh = st.commit()
	# ONE colour for all three signs. Tinting by K would let the sweep measure a
	# palette when the thing under test is a shape.
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.75, 0.38, 0.13)
	mat.roughness = 0.55
	mat.emission_enabled = true
	mat.emission = Color(0.75, 0.38, 0.13)
	mat.emission_energy_multiplier = 0.35
	# Both faces: a saddle and a dome are read from above and below, and this also
	# makes the triangle winding above a non-question.
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	return mi

func _add_normal_pins(host: Node3D, k: float) -> void:
	var half: float = PATCH_SIZE * 0.5
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.15, 0.15)
	mat.emission_enabled = true
	mat.emission = Color(0.35, 0.55, 0.75)
	mat.emission_energy_multiplier = 1.2
	for i in range(PIN_N):
		for j in range(PIN_N):
			var nx: float = -1.0 + 2.0 * float(i) / float(PIN_N - 1)
			var nz: float = -1.0 + 2.0 * float(j) / float(PIN_N - 1)
			var base: Vector3 = Vector3(nx * half, _patch_height(k, nx, nz), nz * half)
			host.add_child(_pin(base, _patch_normal(k, nx, nz), mat))

func _pin(from: Vector3, dir: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0015
	mesh.bottom_radius = 0.0015
	mesh.height = PIN_LEN
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	var y: Vector3 = dir.normalized()
	var ref: Vector3 = Vector3.UP if absf(y.dot(Vector3.UP)) < 0.985 else Vector3.RIGHT
	var x: Vector3 = ref.cross(y).normalized()
	var z: Vector3 = x.cross(y).normalized()
	mi.transform = Transform3D(Basis(x, y, z), from + y * (PIN_LEN * 0.5))
	return mi


# Guarded twice: a word is taken only when it validates against the code's own
# list AND differs, and the rebuild fires only after _ready has built once. The
# body of this function was a bare `pass` before this pass, so the 5 existing
# placements — which name no keys — reach no assignment and never rebuild.
func apply_grid_config(config_data: Dictionary) -> void:
	var dirty: bool = false
	if config_data.has("opening"):
		var o: String = str(config_data["opening"]).to_lower()
		if OPENINGS.has(o) and o != opening:
			opening = o
			dirty = true
	if config_data.has("witness"):
		var w: String = str(config_data["witness"]).to_lower()
		if WITNESSES.has(w) and w != witness:
			witness = w
			dirty = true
	if config_data.has("curvature"):
		var k: float = float(config_data["curvature"])
		if not is_equal_approx(k, curvature):
			curvature = k
			dirty = true
	if not _built or not dirty:
		return
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_slider = null
	_label = null
	_specimen = null
	curvature = _k()
	_create_controls()
	_create_label()
	_create_specimen()
