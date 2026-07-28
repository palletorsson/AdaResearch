# Merge Conflict Visualizer — paraconsistent engineering as visible architecture
#
# Two intersecting pillars come together at a glowing junction. One pillar is labeled
# "branch A" with a blue tint; the other "branch B" with orange. At their meeting, two
# overlapping geometries occupy the same volume — the artifact does NOT pick one. The
# conflict is held, not resolved.
#
# This is paraconsistent logic in three dimensions: hold contradiction without collapse.
# The system continues to function while the two truths coexist.
#
# @identity
# essence: branch A in blue and branch B in orange meet at a glowing junction where both geometries occupy the same volume — and the artifact declines to resolve them
# desire: to give paraconsistent logic a load-bearing body; the engineering room needs contradiction shown as something a system can stand on, not a failure state
# critical_parameter: the junction — the one region where two truths overlap; conflict_color marks it without erasing either branch, and pillar_height keeps both claims equally tall
# triggers: _ready() raises both pillars and the shared junction; _process breathes the conflict glow so held contradiction reads as live, not frozen
# emerges: the felt difference between resolving a conflict and holding one — the structure functions while both truths coexist, which is what production systems quietly do every day
# needs: two CylinderMesh pillars and a junction mesh [Godot built-ins]; emissive conflict material; labels naming the branches so the metaphor stays concrete
# relationships: the applied rung of the paraconsistency ladder — florensky_sphere states both/and as theology, schrodinger_box as physics, this as version control
# truth: a merge conflict is paraconsistency with a deadline. Every system that keeps running while holding two incompatible truths has already abandoned the law of excluded middle — engineering just never says so.
# @qfep_term: Edge — both/and, not either/or.

extends Node3D
class_name MergeConflictVisualizer

@export var branch_a_color: Color = Color(0.45, 0.75, 1.0, 1.0)
@export var branch_b_color: Color = Color(1.0, 0.55, 0.3, 1.0)
@export var conflict_color: Color = Color(1.0, 0.85, 0.3, 1.0)
@export var pillar_height: float = 1.8

## What the two branches actually DO to each other where they meet.
##
## Worth varying because for its whole life this artifact has contradicted its own
## header: the comment above promises "two overlapping geometries occupy the same
## volume", and the code built two posts standing 0.6 m apart that never touch. That
## is a picture of a GAP with a ball hanging in it, not a picture of a conflict.
##
##   junction  the legacy look — two separate uprights, the conflict floating between
##             them, untouched so every shipped placement renders as before
##   overlap   the header made real — the posts lean into each other and their upper
##             halves share one volume, blue inside orange, nothing arbitrated
##   resolved  what merging normally means — branch A takes the centre at full height,
##             branch B survives as a stump. The artifact can now stand next to the
##             thing it refuses.
##   fork      the other failure — both branches lean away, the contradiction falls to
##             the floor between their feet and is stepped over instead of held
##
## The lean angles below move the pillar tops by nearly a metre. A polite few
## centimetres would have been invisible at walking distance and therefore worthless.
@export_enum("junction", "overlap", "resolved", "fork") var merge: String = "junction"

const MERGES: PackedStringArray = ["junction", "overlap", "resolved", "fork"]

## Where each pillar's FOOT stands. Feet never move except under `resolved`, where a
## branch losing its ground is the whole point.
const BASE_X: float = 0.4

## overlap: 14° about z, pivoting at the foot. At 1.8 m tall that swings each top
## 0.44 m inward, so the two centre lines genuinely cross (at y ≈ 1.60) and the box
## volumes interpenetrate from roughly y 1.2 upward — real shared volume, not a
## near miss dressed up by a glow.
const OVERLAP_LEAN_DEG: float = 14.0
const OVERLAP_SPHERE_R: float = 0.35

## fork: 18° swings each top 0.56 m outward — tops at x ±0.95, a 1.9 m spread read
## against a 0.8 m foot spacing. The conflict sphere sits on the floor at ankle height.
const FORK_LEAN_DEG: float = 18.0
const FORK_SPHERE_Y: float = 0.15

## resolved: branch B is not deleted, it is left as a 0.20 m stump. Merges leave scars.
const RESOLVED_STUMP_H: float = 0.20
const RESOLVED_DIM: Color = Color(0.5, 0.5, 0.5, 1.0)

var _t: float = 0.0
var _conflict_glow: MeshInstance3D

## The nodes THIS script made. Only these may ever be freed. The grid adds children of
## its own after _ready — label plates, packaging, tags — and freeing get_children()
## would take those with it.
var _spawned: Array[Node3D] = []

## False until _ready has built once. apply_grid_config can arrive before _ready on the
## grid path, where there is nothing yet to rebuild.
var _built: bool = false


## Build SYNCHRONOUSLY. curation_station calls add_child(inst) and then, on the next
## line, _make_inert(inst) and _hide_labels(inst) — if the pillars and Label3Ds are not
## in place by the time _ready returns, that framing runs on an empty node and this
## artifact's labels go unframed for the whole life of the placement.
func _ready() -> void:
	_build_all()
	_built = true


func apply_grid_config(config_data: Dictionary) -> void:
	var before_merge: String = merge

	# Stage-2 DNA axis — #merge:overlap
	if config_data.has("merge"):
		merge = _pick_axis(str(config_data["merge"]), MERGES, merge)

	if not _built:
		# _ready has not run yet; it will build with the values just resolved.
		return
	if merge == before_merge:
		# Nothing geometric changed. curation_station passes {"emissive": false} to an
		# already-framed instance — rebuilding here would throw away the dark, un-
		# billboarded labels it just applied and never re-apply them.
		return

	_rebuild_now()
	print("[MergeConflictVisualizer] Config applied — merge=%s" % [merge])


## Accept an axis value only if it names something we actually build. A typo in a map
## token has to land on the legacy look whole — a half-applied value would strand a
## placement with leaning pillars and a sphere still hanging where the uprights were.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## remove_child before queue_free: the node leaves the tree in this same frame, so the
## replacement never renders on top of a corpse waiting for the free queue.
func _rebuild_now() -> void:
	for c: Node3D in _spawned:
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_spawned.clear()
	_conflict_glow = null
	_build_all()


func _build_all() -> void:
	match merge:
		"overlap":
			_build_overlap()
		"resolved":
			_build_resolved()
		"fork":
			_build_fork()
		_:
			_build_junction()
	_build_label()


func _process(delta: float) -> void:
	_t += delta * 1.6
	if is_instance_valid(_conflict_glow):
		var mat := _conflict_glow.material_override as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = 2.5 + 1.0 * sin(_t)


# ═══════════════════════════════════════════════════════════════════
# THE FOUR MERGES
# ═══════════════════════════════════════════════════════════════════

## Legacy: two uprights 0.6 m apart, the conflict floating in the air between them.
func _build_junction() -> void:
	var size: Vector3 = Vector3(0.2, pillar_height, 0.2)
	_build_pillar(branch_a_color, Vector3(-BASE_X, 0, 0), size, "branch A", 0.0, false)
	_build_pillar(branch_b_color, Vector3(BASE_X, 0, 0), size, "branch B", 0.0, false)
	_build_conflict_junction(0.25, Vector3(0, pillar_height * 0.6, 0))


## The header's claim, built: both pillars leaned inward so their upper halves occupy
## one volume at x 0, blue and orange interpenetrating with neither cut away.
func _build_overlap() -> void:
	var size: Vector3 = Vector3(0.2, pillar_height, 0.2)
	var lean: float = deg_to_rad(OVERLAP_LEAN_DEG)
	# Negative lean tips a top toward +x, positive toward -x — so the left post leans
	# right and the right post leans left, and they meet over the centre line.
	_build_pillar(branch_a_color, Vector3(-BASE_X, 0, 0), size, "branch A", -lean, false)
	_build_pillar(branch_b_color, Vector3(BASE_X, 0, 0), size, "branch B", lean, false)
	# Height at which the two centre lines actually cross, kept under the tops so the
	# grown sphere sits INSIDE the shared volume rather than capping it.
	var cross_y: float = BASE_X / tan(lean)
	var sphere_y: float = minf(cross_y, pillar_height - OVERLAP_SPHERE_R)
	_build_conflict_junction(OVERLAP_SPHERE_R, Vector3(0, sphere_y, 0))


## The ordinary merge: one branch wins the centre at full height, the other is left as
## a stump with its name greyed out. No conflict sphere — there is nothing being held.
func _build_resolved() -> void:
	_build_pillar(branch_a_color, Vector3(0, 0, 0),
		Vector3(0.2, pillar_height, 0.2), "branch A", 0.0, false)
	_build_pillar(branch_b_color, Vector3(BASE_X, 0, 0),
		Vector3(0.2, RESOLVED_STUMP_H, 0.2), "branch B", 0.0, true)


## The other way contradiction stops being held: both branches lean away, the gap opens
## to 1.9 m at the top, and the conflict drops to the floor between their feet.
func _build_fork() -> void:
	var size: Vector3 = Vector3(0.2, pillar_height, 0.2)
	var lean: float = deg_to_rad(FORK_LEAN_DEG)
	_build_pillar(branch_a_color, Vector3(-BASE_X, 0, 0), size, "branch A", lean, false)
	_build_pillar(branch_b_color, Vector3(BASE_X, 0, 0), size, "branch B", -lean, false)
	_build_conflict_junction(0.25, Vector3(0, FORK_SPHERE_Y, 0))


# ═══════════════════════════════════════════════════════════════════
# BUILDERS
# ═══════════════════════════════════════════════════════════════════

## `base_pos` is the FOOT of the pillar and `lean_rad` rotates it about that foot, so a
## leaned branch keeps its ground and only its top travels. At lean 0 this reduces
## exactly to the original centre-offset build.
func _build_pillar(color: Color, base_pos: Vector3, size: Vector3, label_text: String,
		lean_rad: float, dim_label: bool) -> void:
	var h: float = size.y
	var axis: Vector3 = Vector3(-sin(lean_rad), cos(lean_rad), 0.0)

	var pillar := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	pillar.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.5
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.5
	pillar.material_override = mat
	pillar.position = base_pos + axis * (h * 0.5)
	pillar.rotation.z = lean_rad
	add_child(pillar)
	_spawned.append(pillar)

	var label := Label3D.new()
	label.text = label_text
	label.font_size = 22
	label.outline_size = 5
	var label_color: Color = color
	if dim_label:
		label_color = RESOLVED_DIM
	label.modulate = label_color
	label.position = base_pos + axis * h + Vector3(0, 0.2, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
	_spawned.append(label)


func _build_conflict_junction(radius: float, pos: Vector3) -> void:
	_conflict_glow = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	_conflict_glow.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = conflict_color
	mat.emission_enabled = true
	mat.emission = conflict_color
	mat.emission_energy_multiplier = 2.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.7
	_conflict_glow.material_override = mat
	_conflict_glow.position = pos
	add_child(_conflict_glow)
	_spawned.append(_conflict_glow)


func _build_label() -> void:
	var label := Label3D.new()
	label.text = "hold contradiction, keep running"
	label.font_size = 26
	label.outline_size = 6
	label.modulate = conflict_color
	label.position = Vector3(0, pillar_height + 0.55, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
	_spawned.append(label)
