# Excluded Class Visualizer — algorithmic bias as structural incompleteness
#
# A scatter of points on a plane, separated by a thick straight classification boundary.
# Most points fall cleanly on one side or the other. But a third cluster — pulsing red,
# placed by the boundary — represents the *excluded class*: points the model never had
# enough examples of, points it cannot classify, points outside the training data.
#
# The visualization makes Gödel's claim physical: every formal classifier has a class
# it cannot decide. Bias is not a bug. Bias is the *shape* of the model's outside.
#
# @identity
# essence: two clean point clusters, one confident boundary, and a third cluster pulsing red beside the line — the class the model never had words for, standing where the training data ends
# desire: to make Gödel physical for machine learning; the bias room needs incompleteness as something you can walk around, not a statistic you are told
# critical_parameter: excluded_count against class_count_each — how large the undecidable region reads next to the decided ones; the boundary's confidence never changes, which is the point
# triggers: _ready() scatters both classes, places the excluded cluster and the boundary; the excluded points pulse on _process time so the eye cannot file them as background
# emerges: bias stops reading as error and starts reading as shape — every classifier drawn this sharply has an outside, and the outside has residents
# needs: SphereMesh points and a BoxMesh boundary [Godot built-ins]; emission on the excluded cluster; a floor plane to hold the scatter at examination height
# relationships: the applied rung of the bias ladder — algorithmic_bias supplies the mechanism (asymmetric errors), this supplies the geometry of who is outside it
# truth: bias is not a bug in the model. Bias is the shape of the model's outside, and no amount of training removes the outside — it only moves the border.
# @qfep_term: Edge — incompleteness as constitutive.

extends Node3D
class_name ExcludedClassVisualizer

@export var class_a_color: Color = Color(0.45, 0.85, 1.0, 1.0)
@export var class_b_color: Color = Color(1.0, 0.85, 0.4, 1.0)
@export var excluded_color: Color = Color(1.0, 0.35, 0.4, 1.0)
@export var boundary_color: Color = Color(0.7, 0.7, 0.8, 1.0)
@export var domain_size: float = 1.8
@export var class_count_each: int = 30
@export var excluded_count: int = 10

# ── Stage-2 DNA axis ─────────────────────────────────────────────────
## How much of the domain the model cannot decide — and whether that region is
## shown at all. Severity of the exclusion is the one number this object is
## entirely about, and until now it was the one number a map could not touch:
## ten red spheres against sixty classified points, forever, a tidy 14% anomaly
## hugging a razor-thin line. That is the polite case. It is not the only case,
## and pretending it is, is the argument this artifact exists to refuse.
##
## An ordered ladder — none, sliver, slab, flood — lets a map state the scope of
## a *specific* model's outside:
##
##   erased    the published figure. Zero red spheres, no excluded-class label —
##             and, crucially, no hole where they were. The domain CLOSES over
##             the gap: the floor narrows by the width of the excised band
##             (1.80 m → 1.64 m in x), the two classified fields grow inward to
##             x = 0 and thicken by half again (45 points each, 90 total against
##             fringe's 60), and a solid class-coloured plate seals the ±0.08 m
##             sliver the red spheres used to occupy. Erasure is not subtraction
##             leaving a scar; it is the space rewritten as if the outside had
##             never had a place in it. This is the artifact's actual quarry.
##   fringe    the legacy look, unchanged: 10 red spheres in the ±0.08 m sliver.
##   slab      the boundary widens into a 0.5 m plate; 40 red spheres fill it and
##             the classified points are shoved out past |x| 0.35. The undecidable
##             band takes more than a quarter of the domain.
##   majority  90 red spheres flood the whole 1.8 m field while each class shrinks
##             to 8 points huddled in a far corner. The line still cuts — it just
##             cuts a field that is mostly outside.
##
## Every rung changes sphere COUNT and domain OCCUPANCY, so the difference is
## legible from across the room, not a 5 cm nuance a walking player would miss.
@export_enum("erased", "fringe", "slab", "majority") var exclusion: String = "fringe"

## Allow-list for the axis. Anything unrecognised falls back to the legacy look
## rather than half-applying — a typo in a map token must not strand a placement
## with a boundary plate and no points, or a flood and no line.
const EXCLUSIONS: PackedStringArray = ["erased", "fringe", "slab", "majority"]

## Geometry constants per rung, so the numbers the spec names live in one place.
const BAND_FRINGE: float = 0.08      # ±m the undecidable sliver occupies
const BAND_SLAB: float = 0.25        # ±m — the full half-width of the 0.5 m plate
const BOUNDARY_W_THIN: float = 0.02  # the razor line
const BOUNDARY_W_SLAB: float = 0.5   # the plate
const CLASS_INNER_FRINGE: float = 0.15
const CLASS_INNER_SLAB: float = 0.35 # points pushed clear of the plate
const CLASS_INNER_CLOSED: float = 0.0 # erased: the field runs right up to the line
const CLASS_CLOSED_MULT: float = 1.5 # erased: the field thickens as it closes over
const EXCLUDED_R_NORMAL: float = 0.05
const EXCLUDED_R_FLOOD: float = 0.06
const EXCLUDED_N_SLAB: int = 40
const EXCLUDED_N_FLOOD: int = 90
const CLASS_N_CORNERED: int = 8

## Fixed seed so two builds of the same axis value are pixel-identical. A pixel
## critic diffs renders to decide whether an axis is real; per-build scatter
## jitter would make an inert axis look alive and a live one look noisy.
const BUILD_SEED: int = 20260728

var _t: float = 0.0
var _excluded_nodes: Array = []
## Every node THIS script created, in creation order. Only these are freed on a
## rebuild — label plates, packaging and tags added by the grid system are not
## ours to destroy.
var _created_nodes: Array = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _built: bool = false


func _ready() -> void:
	_build_all()
	_built = true


func _build_all() -> void:
	_rng.seed = BUILD_SEED
	_build_floor()
	_build_classes()
	_build_closure()
	_build_excluded()
	_build_boundary()
	_build_label()


func apply_grid_config(config_data: Dictionary) -> void:
	# Stage-2 DNA axis — #exclusion:slab
	var before_exclusion: String = exclusion
	if config_data.has("exclusion"):
		exclusion = _pick_axis(str(config_data["exclusion"]), EXCLUSIONS, exclusion)

	if not _built:
		return  # _ready has not run yet; it will build with these values.
	if exclusion == before_exclusion:
		return  # nothing geometric changed — leave the placement exactly as it stands.

	_rebuild_now()
	print("[ExcludedClassVisualizer] Config applied — exclusion=%s (classes=%d each, excluded=%d)" % [
		exclusion, _class_points_each(), _excluded_points()])


## Accept an axis value only if it names something we actually build. A typo in a
## map token has to land on the legacy look, never half-apply.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## Synchronous, inline, and scoped to our own children. Nothing deferred: the
## grid path frames labels and grounds the artifact immediately after add_child,
## and a deferred rebuild would land after both and undo them.
func _rebuild_now() -> void:
	for node in _created_nodes:
		if is_instance_valid(node):
			remove_child(node)
			node.queue_free()
	_created_nodes.clear()
	_excluded_nodes.clear()
	_build_all()


## Every add_child in this script goes through here, so the tracked list and the
## tree can never drift apart.
func _spawn(node: Node) -> void:
	add_child(node)
	_created_nodes.append(node)


func _process(delta: float) -> void:
	_t += delta * 0.9
	for node in _excluded_nodes:
		if not is_instance_valid(node):
			continue
		var mat := (node as MeshInstance3D).material_override as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = 1.6 + 0.8 * sin(_t + node.position.x * 5.0)


# ═══════════════════════════════════════════════════════════════════
# AXIS RESOLUTION — one function per quantity the ladder moves
# ═══════════════════════════════════════════════════════════════════

## Points per classified class. Author-set everywhere except `majority`, where
## the two classes are reduced to a huddle by definition, and `erased`, where the
## decided field thickens as it grows over the band it wrote out.
func _class_points_each() -> int:
	if exclusion == "majority":
		return CLASS_N_CORNERED
	if exclusion == "erased":
		return int(round(float(class_count_each) * CLASS_CLOSED_MULT))
	return class_count_each


func _excluded_points() -> int:
	match exclusion:
		"erased":
			return 0
		"slab":
			return EXCLUDED_N_SLAB
		"majority":
			return EXCLUDED_N_FLOOD
		_:
			return excluded_count


## Half-width of the region the undecidable points occupy.
func _excluded_band() -> float:
	match exclusion:
		"slab":
			return BAND_SLAB
		"majority":
			return domain_size * 0.45
		_:
			return BAND_FRINGE


func _excluded_radius() -> float:
	if exclusion == "majority":
		return EXCLUDED_R_FLOOD
	return EXCLUDED_R_NORMAL


## How far from the line the classified points must start. `slab` pushes them out
## — the plate would otherwise swallow points the model does in fact decide.
## `erased` pulls them all the way in: there is no band to leave clear.
func _class_inner_x() -> float:
	if exclusion == "slab":
		return CLASS_INNER_SLAB
	if exclusion == "erased":
		return CLASS_INNER_CLOSED
	return CLASS_INNER_FRINGE


## Outer edge of the classified scatter. On `erased` the whole domain has closed
## inward by the width of the excised band, so the far edge comes in with it.
func _class_outer_x() -> float:
	if exclusion == "erased":
		return domain_size * 0.45 - BAND_FRINGE
	return domain_size * 0.45


## X extent of the floor. `erased` narrows it: the space the excluded class
## occupied is not left empty, it is gone.
func _floor_x_size() -> float:
	if exclusion == "erased":
		return domain_size - 2.0 * BAND_FRINGE
	return domain_size


func _boundary_width() -> float:
	if exclusion == "slab":
		return BOUNDARY_W_SLAB
	return BOUNDARY_W_THIN


# ═══════════════════════════════════════════════════════════════════
# BUILDERS
# ═══════════════════════════════════════════════════════════════════

func _build_floor() -> void:
	var floor := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(_floor_x_size(), 0.02, domain_size)
	floor.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.16, 0.2, 1.0)
	floor.material_override = mat
	_spawn(floor)


func _build_classes() -> void:
	# Class A on the left of the boundary; Class B on the right.
	var count: int = _class_points_each()
	var inner: float = _class_inner_x()
	var outer: float = _class_outer_x()
	var cornered: bool = exclusion == "majority"
	for class_data in [
		{"side": -1.0, "color": class_a_color},
		{"side": 1.0, "color": class_b_color},
	]:
		var side: float = class_data["side"]
		for i in count:
			var sphere := MeshInstance3D.new()
			var s := SphereMesh.new()
			s.radius = 0.04
			s.height = 0.08
			sphere.mesh = s
			var mat := StandardMaterial3D.new()
			mat.albedo_color = class_data["color"]
			mat.emission_enabled = true
			mat.emission = class_data["color"]
			mat.emission_energy_multiplier = 1.0
			sphere.material_override = mat
			var x: float = 0.0
			var z: float = 0.0
			if cornered:
				# Two far corners, diagonally opposed: what is left of a class
				# when the outside takes the middle.
				x = side * _rng.randf_range(domain_size * 0.34, domain_size * 0.45)
				z = side * _rng.randf_range(domain_size * 0.24, domain_size * 0.4)
			else:
				# Side scatter.
				x = side * _rng.randf_range(inner, outer)
				z = _rng.randf_range(-domain_size * 0.4, domain_size * 0.4)
			sphere.position = Vector3(x, 0.06, z)
			_spawn(sphere)


## `erased` only: two solid class-coloured plates that seal the ±0.08 m strip the
## red spheres used to hold. Without them the rung would be defined purely by an
## absence — a gap where the outside was. With them the majority field has visibly
## grown over the ground, which is the claim: not pushed to the fringe, written out.
func _build_closure() -> void:
	if exclusion != "erased":
		return
	for plate_data in [
		{"side": -1.0, "color": class_a_color},
		{"side": 1.0, "color": class_b_color},
	]:
		var side: float = plate_data["side"]
		var plate := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(BAND_FRINGE, 0.03, domain_size * 0.9)
		plate.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = plate_data["color"]
		mat.emission_enabled = true
		mat.emission = plate_data["color"]
		mat.emission_energy_multiplier = 0.7
		plate.material_override = mat
		plate.position = Vector3(side * BAND_FRINGE * 0.5, 0.025, 0.0)
		_spawn(plate)


func _build_excluded() -> void:
	# Excluded class sits ON the boundary — undecidable. On `erased` it is not
	# built at all: the figure that got published is the figure with no red in it.
	var count: int = _excluded_points()
	if count <= 0:
		return
	var band: float = _excluded_band()
	var radius: float = _excluded_radius()
	var z_reach: float = domain_size * 0.4
	if exclusion == "majority":
		z_reach = domain_size * 0.45
	for i in count:
		var sphere := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = radius
		s.height = radius * 2.0
		sphere.mesh = s
		var mat := StandardMaterial3D.new()
		mat.albedo_color = excluded_color
		mat.emission_enabled = true
		mat.emission = excluded_color
		mat.emission_energy_multiplier = 1.8
		sphere.material_override = mat
		var x: float = _rng.randf_range(-band, band)
		var z: float = _rng.randf_range(-z_reach, z_reach)
		sphere.position = Vector3(x, 0.08, z)
		_spawn(sphere)
		_excluded_nodes.append(sphere)


func _build_boundary() -> void:
	var line := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(_boundary_width(), 0.05, domain_size)
	line.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = boundary_color
	mat.emission_enabled = true
	mat.emission = boundary_color
	mat.emission_energy_multiplier = 1.2
	line.material_override = mat
	line.position.y = 0.055 if exclusion == "erased" else 0.04
	_spawn(line)


func _build_label() -> void:
	# `erased` omits it. Naming the excluded class is exactly what the published
	# figure does not do, and a caption pointing at nothing would be a different
	# claim than the one this rung makes.
	if exclusion == "erased":
		return
	var label := Label3D.new()
	label.text = "the class the classifier cannot see"
	label.font_size = 24
	label.outline_size = 5
	label.modulate = excluded_color
	label.position = Vector3(0, 0.95, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_spawn(label)
