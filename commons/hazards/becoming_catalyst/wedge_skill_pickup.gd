# @identity
# essence: wireframe_cube(1m) -> skill_unlock(wedge_placer) -- a cage holding the wedge power
# desire: to be discovered mid-sequence, expanding what the player can build
# critical_parameter: unlock triggers only once — the wedge mode persists for the session
# triggers: player enters primitives sequence; walks to the pickup; grabs the prism
# emerges: the second tool in the builder's kit — slopes, ramps, angles
# needs: CapacityBracelet [adds gem]; BecomingCatalyst [adds mode]; wireframe cage [has]
# relationships: sibling to catalyst_pedestal; found in primitives sequence; second bracelet stone
# truth: the wedge teaches that not everything fits in a box.

# WedgeSkillPickup.gd
# A one-meter wireframe cube containing a floating prism. When the player grabs
# the prism, the "wedge_placer" mode is unlocked on their catalyst bracelet.
# The cage fades and the prism disappears — the skill now lives on the bracelet.
#
# Place in map_data.json interactables layer as "wedge_skill_pickup".

## STAGE-2 DNA PROMOTION (2026-07-29).
##
## Before this the script had zero exports and apply_grid_config() was a bare
## `pass`. The cage was not a neutral container: a wireframe cube around a power
## says the power is confined, catalogued, a specimen you must reach into. That
## was an unexamined constant. Two axes —
##
##   housing  HOW THE SKILL IS KEPT UNTIL IT IS YOURS   cage · plinth · open
##   after    WHAT THE SITE DOES ONCE IT IS TAKEN       fade · remain
##
##   cage    the wireframe cube (pre-promotion behaviour, the default).
##   plinth  a solid column under the prism, nothing above it. The power is
##           offered, ceremonially, rather than confined.
##   open    no housing at all. The power lies about in the room, unguarded —
##           a capability nobody thought to fence.
##
##   fade    the housing dissolves and the artifact frees itself. The site of
##           acquisition erases the fact that anything was here (default).
##   remain  the housing stays, dimmed and empty, a scar marking that something
##           was taken from this spot.
##
## `after` is a time-domain axis — it is invisible to a still capture and only
## reads once the prism has been grabbed.

extends Node3D
class_name WedgeSkillPickup

## How the skill is kept before it is yours: cage, plinth, or open.
@export var housing: String = "cage"
## What the site does after collection: fade (dissolve and free) or remain (dim, empty).
@export var after: String = "fade"

const CAGE_SIZE := 1.0
const PLINTH_HEIGHT := 0.42
const EDGE_THICKNESS := 0.006
const CAGE_COLOR := Color(0.85, 0.55, 0.2, 0.8)  # Warm orange — wedge identity
const BOB_SPEED := 1.0
const BOB_AMOUNT := 0.03
const SPIN_SPEED := 0.6
const FADE_TIME := 1.5

var _cage: Node3D = null
var _plinth: Node3D = null
var _built: bool = false
var _prism_visual: MeshInstance3D = null
var _prism_pickable: RigidBody3D = null
var _cage_light: OmniLight3D = null
var _edge_materials: Array[StandardMaterial3D] = []
var _base_y: float = 0.0
var _fading: bool = false
var _fade_progress: float = 0.0
var _collected: bool = false

signal skill_collected()


func _ready() -> void:
	_build_housing()
	_build_light()
	_build_prism_pickable()
	_built = true


## Dispatch on the housing axis. housing="cage" calls the original builder
## unchanged, so every existing placement is byte-for-byte what it was.
func _build_housing() -> void:
	match housing:
		"plinth":
			_build_plinth()
		"open":
			pass
		_:
			_build_cage()


func _process(delta: float) -> void:
	# Prism hover and spin
	if is_instance_valid(_prism_pickable) and not _fading and not _collected:
		var bob := sin(Time.get_ticks_msec() / 1000.0 * BOB_SPEED) * BOB_AMOUNT
		_prism_pickable.position.y = _base_y + bob
		if _prism_visual:
			_prism_visual.rotation.y += SPIN_SPEED * delta

	# Light pulse
	if _cage_light and not _fading:
		var pulse := 1.2 + sin(Time.get_ticks_msec() / 600.0) * 0.4
		_cage_light.light_energy = pulse

	# Cage fade
	if _fading:
		_fade_progress += delta / FADE_TIME
		if _fade_progress >= 1.0:
			if after == "remain":
				# The site keeps its shape, dimmed — a scar where a power was taken.
				_fading = false
				_fade_progress = 1.0
				for mat in _edge_materials:
					mat.albedo_color.a = 0.18
					mat.emission_energy_multiplier = 0.15
				if _cage_light:
					_cage_light.light_energy = 0.15
				return
			queue_free()
			return
		var alpha := 1.0 - _fade_progress
		for mat in _edge_materials:
			mat.albedo_color.a = alpha * 0.8
			mat.emission_energy_multiplier = (1.0 - _fade_progress) * 2.0
		if _cage_light:
			_cage_light.light_energy = (1.0 - _fade_progress) * 1.2


# ═══════════════════════════════════════════════════════════════════════════
# CAGE — same wireframe cube as catalyst_pedestal but orange
# ═══════════════════════════════════════════════════════════════════════════

func _build_cage() -> void:
	_cage = Node3D.new()
	_cage.name = "Cage"
	add_child(_cage)

	var half := CAGE_SIZE * 0.5
	var v := [
		Vector3(-half, 0.0, -half), Vector3(half, 0.0, -half),
		Vector3(half, 0.0, half), Vector3(-half, 0.0, half),
		Vector3(-half, CAGE_SIZE, -half), Vector3(half, CAGE_SIZE, -half),
		Vector3(half, CAGE_SIZE, half), Vector3(-half, CAGE_SIZE, half),
	]
	var edges := [
		[v[0],v[1]], [v[1],v[2]], [v[2],v[3]], [v[3],v[0]],
		[v[4],v[5]], [v[5],v[6]], [v[6],v[7]], [v[7],v[4]],
		[v[0],v[4]], [v[1],v[5]], [v[2],v[6]], [v[3],v[7]],
	]
	for i in edges.size():
		_build_edge(edges[i][0], edges[i][1], i)


func _build_edge(start: Vector3, end_pos: Vector3, idx: int) -> void:
	var mid := (start + end_pos) * 0.5
	var length := start.distance_to(end_pos)
	var dir := (end_pos - start).normalized()

	var cyl := CylinderMesh.new()
	cyl.top_radius = EDGE_THICKNESS
	cyl.bottom_radius = EDGE_THICKNESS
	cyl.height = length
	cyl.radial_segments = 6

	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "Edge%d" % idx
	mesh_inst.mesh = cyl

	var mat := StandardMaterial3D.new()
	mat.albedo_color = CAGE_COLOR
	mat.emission_enabled = true
	mat.emission = Color(CAGE_COLOR.r, CAGE_COLOR.g, CAGE_COLOR.b)
	mat.emission_energy_multiplier = 2.0
	mat.metallic = 0.7
	mat.roughness = 0.15
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_inst.material_override = mat
	_cage.add_child(mesh_inst)
	_edge_materials.append(mat)

	mesh_inst.position = mid
	if not dir.is_equal_approx(Vector3.UP) and not dir.is_equal_approx(Vector3.DOWN):
		var up := Vector3.UP
		var axis := up.cross(dir).normalized()
		var angle := up.angle_to(dir)
		if axis.length() > 0.001:
			mesh_inst.transform.basis = Basis(axis, angle)
			mesh_inst.position = mid


# ═══════════════════════════════════════════════════════════════════════════
# PLINTH — housing="plinth". A column under the prism and nothing above it:
# the power offered rather than confined. Reached only via the axis.
# ═══════════════════════════════════════════════════════════════════════════

func _build_plinth() -> void:
	_plinth = Node3D.new()
	_plinth.name = "Plinth"
	add_child(_plinth)

	var shaft := CylinderMesh.new()
	shaft.top_radius = 0.13
	shaft.bottom_radius = 0.19
	shaft.height = PLINTH_HEIGHT
	shaft.radial_segments = 16
	_add_plinth_piece(shaft, "PlinthShaft", Vector3(0, PLINTH_HEIGHT * 0.5, 0))

	var cap := CylinderMesh.new()
	cap.top_radius = 0.21
	cap.bottom_radius = 0.21
	cap.height = 0.03
	cap.radial_segments = 16
	_add_plinth_piece(cap, "PlinthCap", Vector3(0, PLINTH_HEIGHT + 0.015, 0))


func _add_plinth_piece(mesh: Mesh, piece_name: String, pos: Vector3) -> void:
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = piece_name
	mesh_inst.mesh = mesh
	mesh_inst.position = pos

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(CAGE_COLOR.r * 0.45, CAGE_COLOR.g * 0.4, CAGE_COLOR.b * 0.35, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(CAGE_COLOR.r, CAGE_COLOR.g, CAGE_COLOR.b)
	mat.emission_energy_multiplier = 0.3
	mat.metallic = 0.55
	mat.roughness = 0.35
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_inst.material_override = mat

	_plinth.add_child(mesh_inst)
	_edge_materials.append(mat)


func _build_light() -> void:
	_cage_light = OmniLight3D.new()
	_cage_light.name = "CageLight"
	_cage_light.light_color = Color(0.85, 0.6, 0.3)
	_cage_light.light_energy = 1.2
	_cage_light.omni_range = 2.0
	_cage_light.omni_attenuation = 1.5
	_cage_light.position = Vector3(0, CAGE_SIZE * 0.5, 0)
	add_child(_cage_light)


# ═══════════════════════════════════════════════════════════════════════════
# PRISM — the pickable skill token
# ═══════════════════════════════════════════════════════════════════════════

func _build_prism_pickable() -> void:
	# Use XRToolsPickable for VR grabbing
	var pickable_scene = load("res://addons/godot-xr-tools/objects/pickable.tscn")
	if pickable_scene:
		_prism_pickable = pickable_scene.instantiate()
	else:
		_prism_pickable = RigidBody3D.new()

	_prism_pickable.name = "WedgePrism"
	_prism_pickable.freeze = true
	_prism_pickable.collision_layer = 4  # Pickable layer
	_prism_pickable.collision_mask = 0

	_base_y = CAGE_SIZE * 0.5
	_prism_pickable.position = Vector3(0, _base_y, 0)

	# Collision shape
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.15, 0.12, 0.15)
	col.shape = box
	_prism_pickable.add_child(col)

	# Visual prism mesh
	_prism_visual = MeshInstance3D.new()
	_prism_visual.name = "PrismMesh"
	var prism := PrismMesh.new()
	prism.size = Vector3(0.12, 0.1, 0.12)
	prism.left_to_right = 0.0
	_prism_visual.mesh = prism
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.55, 0.2, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(0.85, 0.55, 0.2)
	mat.emission_energy_multiplier = 2.5
	mat.metallic = 0.4
	mat.roughness = 0.2
	_prism_visual.material_override = mat
	_prism_pickable.add_child(_prism_visual)

	add_child(_prism_pickable)

	# Connect pickup signal
	if _prism_pickable.has_signal("picked_up"):
		_prism_pickable.picked_up.connect(_on_prism_grabbed)


func _on_prism_grabbed(_pickable) -> void:
	if _collected:
		return
	_collected = true

	# Unlock wedge_placer on the player's catalyst
	var catalysts = get_tree().get_nodes_in_group("catalyst")
	for cat in catalysts:
		if cat.has_method("_unlock_mode"):
			cat._unlock_mode("wedge_placer", true)
			print("[WedgePickup] Unlocked wedge_placer on catalyst")
			break

	# Release the prism from the hand and destroy it
	if _prism_pickable.has_method("let_go"):
		var holder = _prism_pickable.get_picked_up_by() if _prism_pickable.has_method("get_picked_up_by") else null
		if holder:
			_prism_pickable.let_go(holder, Vector3.ZERO, Vector3.ZERO)
	_prism_pickable.queue_free()

	# Fade the cage
	_fading = true
	_fade_progress = 0.0
	skill_collected.emit()
	print("[WedgePickup] Skill collected — cage fading")


## Guarded: `after` is a plain assignment (nothing to rebuild), and the housing is
## only rebuilt when the token actually names a different one AND _ready has
## already built once. A placement that passes no housing token never rebuilds.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("after"):
		after = str(config_data["after"])

	if not config_data.has("housing"):
		return
	var want: String = str(config_data["housing"])
	if want == "" or want == housing:
		return
	housing = want
	if not _built or _collected or _fading or not is_inside_tree():
		return
	_rebuild_housing()


## Swaps only the housing. The prism, the light and the collected state are left
## exactly where they are — nothing about the pickup itself is re-created.
func _rebuild_housing() -> void:
	if is_instance_valid(_cage):
		_cage.queue_free()
	_cage = null
	if is_instance_valid(_plinth):
		_plinth.queue_free()
	_plinth = null
	_edge_materials.clear()
	_build_housing()
