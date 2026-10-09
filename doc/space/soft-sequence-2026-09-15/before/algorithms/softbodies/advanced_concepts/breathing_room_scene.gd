extends Node3D
# ─────────────────────────────────────────────────────────────────────────────
# breathing_room — STAGE-2 DNA (promoted 2026-08-04). axes: substance, aperture
#
# READ THIS BEFORE EDITING, BECAUSE THE FILE NAME IS A TRAP.
# breathing_room.tscn is the registry's scene for the token `breathing_room`,
# and until today its root node carried NO SCRIPT. The sibling breathing_room.gd
# — the one with the sinusoidal pressure loop the registry description promises
# — is loaded by nothing: no .tscn, no .gd, no registry entry names it (checked
# across the repo). Its _ready() builds a DIFFERENT room from scratch (its own
# camera, floor, ceiling and two procedural walls at room_size 6x4x10), so
# attaching it here would not have added an axis, it would have stood a second
# room inside the first one in twelve maps.
#
# So this file exists instead: the script that runs THE SHIPPED SCENE. What the
# player actually meets is two hand-authored SoftBody3D slabs, 1 x 4 x 7, at
# x = -2.3185759 and x = +3.5541987, edges pinned by baked point indices, no
# material override on either, and no breathing — the room in the twelve maps
# has never once inhaled. That is the honest starting point for the axes, and
# it is also why neither axis is a rate: the evidence for one is a single still.
#
# WHAT WAS HARD-CODED AND IS NOW SAID OUT LOUD:
#
#   substance — the walls have no material_override, so they render in Godot's
#     default grey. The corridor therefore argues CONTAINER. The artifact's own
#     truth line says the opposite ("a room that breathes is no longer a
#     container — it is a body, and you are inside it"), and the orphan script
#     carries the flesh material that was meant to say so: albedo (0.8,0.5,0.5)
#     with skin-mode subsurface scattering. That material is reachable from a
#     map for the first time here, character for character. `substance` is the
#     word rainbow and sculpt_one already use for what a thing is made of, and
#     solid / glass / fabric are their values verbatim; flesh is the one this
#     artifact needs and they do not have.
#
#   aperture — the two slabs stand 4.87 m apart at the inner faces, and that
#     gap is the whole subject. It is what the breathing WOULD modulate, and in
#     a still it is the only form the breath can take: the phase you catch it
#     at. closed is a room that has finished exhaling around you; wide is a
#     hall that has stopped noticing you. `ajar` is the authored gap.
#
# BOTH DEFAULTS ARE STRICT NO-OPS. `solid` returns before a material is
# constructed and `ajar` returns before a transform is read, so the five grid
# tokens (SoftBodies_Obsticals, _p1, _p2, _p3, Corridor_SoftBodies_Obsticals),
# the six exhibit_furniture mounts in the Trial_* museums and the
# Curation_Bay_softbodies_0 roster all render precisely what they rendered
# before. No map carries a #substance: or #aperture: token today.
#
# WHY THE APERTURE MOVE HAPPENS IN _enter_tree AND NOT _ready. A SoftBody3D
# fixes its empty-path pinned points to WORLD space when its physics body is
# created on entering the tree, and Godot's soft bodies do not follow their
# node transform afterwards. Children enter after their parent, so _enter_tree
# is the last moment the slabs can still be placed. Both callers cooperate:
# GridInteractablesComponent stamps config_* metadata synchronously before
# add_child (line 1195 vs 1220), and capture_config_sweep sets the swept
# @export before add_child too — so the value is on the object either way by
# the time this runs.
# ─────────────────────────────────────────────────────────────────────────────

## What the walls are made of. `solid` is the shipped look — no material
## override at all, Godot's default grey — and its branch never builds a
## material. Set from a map with `breathing_room#substance:flesh`.
@export_enum("solid", "flesh", "glass", "fabric") var substance: String = "solid"

## How far open the corridor stands: the phase of the breath a still catches.
## `ajar` is the authored gap and leaves both transforms untouched. Set from a
## map with `breathing_room#aperture:closed`.
@export_enum("ajar", "closed", "narrow", "wide") var aperture: String = "ajar"

const SUBSTANCES := ["solid", "flesh", "glass", "fabric"]
const APERTURES := ["ajar", "closed", "narrow", "wide"]

# Half the distance between the two slab centres, in metres. `ajar` is
# deliberately ABSENT: its meaning is "whatever the .tscn authored", which is
# read from the scene at runtime rather than copied here, so a future nudge to
# either transform cannot silently disagree with this table.
const APERTURE_HALF := {
	"closed": 0.75,
	"narrow": 1.6,
	"wide": 4.2,
}

var _walls: Array[SoftBody3D] = []
var _home_x := PackedFloat32Array()
var _moved: bool = false
var _skinned: bool = false


func _enter_tree() -> void:
	if has_meta("config_substance"):
		substance = _pick_axis(str(get_meta("config_substance")), SUBSTANCES, substance)
	if has_meta("config_aperture"):
		aperture = _pick_axis(str(get_meta("config_aperture")), APERTURES, aperture)
	_collect_walls()
	_apply_aperture()


func _ready() -> void:
	# Materials are safe at any time, so they wait until the scene is up.
	_apply_substance()


func _pick_axis(value: String, allowed: Array, fallback: String) -> String:
	# An unrecognised value keeps the shipped default rather than half-applying
	# one. Silence here is the science_screen disease: an invalid value falls
	# back, every frame comes out identical, and the sweep reports the axis inert
	# when the real fact is a typo. So it warns.
	var v: String = value.strip_edges().to_lower()
	if allowed.has(v):
		return v
	if v != "":
		push_warning("breathing_room: unknown value '%s'; keeping '%s'" % [value, fallback])
	return fallback


func _collect_walls() -> void:
	_walls.clear()
	for child in get_children():
		if child is SoftBody3D:
			_walls.append(child as SoftBody3D)
	if _home_x.size() != _walls.size():
		_home_x = PackedFloat32Array()
		for sb in _walls:
			_home_x.append(sb.position.x)


func _apply_aperture() -> void:
	# Only the two-slab corridor the .tscn authors is understood. Anything else
	# is left alone rather than guessed at.
	if _walls.size() != 2 or _home_x.size() != 2:
		return
	if aperture == "ajar" and not _moved:
		return  # THE SHIPPED PATH: neither transform is read or written
	var lo: int = 0
	var hi: int = 1
	if _home_x[0] > _home_x[1]:
		lo = 1
		hi = 0
	# Always measured from the AUTHORED positions, never from wherever a
	# previous value left the slabs, so the values stay a fixed scale and
	# `ajar` restores the scene exactly.
	var target_lo: float = _home_x[lo]
	var target_hi: float = _home_x[hi]
	if APERTURE_HALF.has(aperture):
		var half: float = float(APERTURE_HALF[aperture])
		var centre: float = (float(_home_x[0]) + float(_home_x[1])) * 0.5
		target_lo = centre - half
		target_hi = centre + half
		_moved = true
	else:
		_moved = false
	var wall_lo: SoftBody3D = _walls[lo]
	var wall_hi: SoftBody3D = _walls[hi]
	var pos_lo: Vector3 = wall_lo.position
	pos_lo.x = target_lo
	wall_lo.position = pos_lo
	var pos_hi: Vector3 = wall_hi.position
	pos_hi.x = target_hi
	wall_hi.position = pos_hi


func _apply_substance() -> void:
	if _walls.is_empty():
		_collect_walls()
	if substance == "solid":
		if not _skinned:
			return  # THE SHIPPED PATH: material_override is never assigned
		for sb in _walls:
			sb.material_override = null
		_skinned = false
		return
	var mat := StandardMaterial3D.new()
	match substance:
		"flesh":
			# Verbatim from breathing_room.gd's create_breathing_wall(), the
			# material the orphan demo always meant these walls to have.
			mat.albedo_color = Color(0.8, 0.5, 0.5)
			mat.subsurf_scatter_enabled = true
			mat.subsurf_scatter_strength = 0.8
			mat.subsurf_scatter_skin_mode = true
		"glass":
			mat.albedo_color = Color(0.55, 0.72, 0.78, 0.32)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			mat.roughness = 0.05
			mat.metallic = 0.15
		"fabric":
			mat.albedo_color = Color(0.62, 0.60, 0.55)
			mat.roughness = 1.0
			mat.metallic = 0.0
		_:
			return
	for sb in _walls:
		sb.material_override = mat
	_skinned = true


func apply_grid_config(config: Dictionary) -> void:
	# GUARDED THREE WAYS: the key must be present, the value must be one the code
	# can build, and it must DIFFER from what is already standing. This arrives
	# call_deferred, after _ready — an unconditional re-apply here is exactly
	# what breaks shipped placements.
	#
	# For a map token this channel is redundant: the same value arrived as
	# config_* metadata before add_child and was honoured in _enter_tree. It is
	# kept for the delegate/roster callers that only have this one, with the
	# caveat that an aperture set THIS late cannot move a soft body whose
	# physics body already exists — the substance still applies.
	if config.has("substance"):
		var want_substance: String = _pick_axis(str(config["substance"]), SUBSTANCES, substance)
		if want_substance != substance:
			substance = want_substance
			_apply_substance()
	if config.has("aperture"):
		var want_aperture: String = _pick_axis(str(config["aperture"]), APERTURES, aperture)
		if want_aperture != aperture:
			aperture = want_aperture
			_apply_aperture()
