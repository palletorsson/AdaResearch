# @identity
# essence: wireframe_cube(1m) -> display_case(catalyst) -- a glowing cage that presents the crystal
# desire: to be noticed, approached, and opened — the first thing the player reaches for
# critical_parameter: cage_color / crystal_hover_height -- the wireframe must say "pick me up"
# triggers: player enters lab; catalyst not yet absorbed; visual beacon draws the eye
# emerges: the moment before transformation — the tool exists, waiting to be claimed
# needs: BecomingCatalyst scene [spawns]; wireframe rendering [has]; slow rotation [has]
# relationships: contains becoming_catalyst; inspired by cube_lines aesthetic; lives in lab spawn area
# truth: the cage doesn't protect the crystal — it frames the invitation.

# CatalystPedestal.gd
# A one-meter wireframe cube display case with the Becoming Catalyst floating
# inside. Place this in lab maps instead of a raw becoming_catalyst. The player
# walks up, sees the glowing crystal rotating inside the wireframe cage, and
# grabs it — at which point the crystal absorbs into their hand and the cage
# fades away.
#
# Visual: 12 glowing cyan edges (like cube_lines) + catalyst crystal hovering
# at center + gentle bob + slow rotation + point light.

extends Node3D
class_name CatalystPedestal

const CAGE_SIZE := 1.0          # 1 meter cube
const EDGE_THICKNESS := 0.006   # Thin wireframe lines
const CAGE_COLOR := Color(0.3, 0.65, 1.0, 0.8)  # Cyan like cube_lines
const CRYSTAL_BOB_SPEED := 1.2  # Gentle vertical bob
const CRYSTAL_BOB_AMOUNT := 0.04
const CRYSTAL_SPIN_SPEED := 0.4  # Slow Y rotation (rad/s)
const CAGE_FADE_TIME := 1.5     # Seconds to fade cage after pickup

var _cage: Node3D = null
var _crystal: Node3D = null       # The BecomingCatalyst instance
var _cage_light: OmniLight3D = null
var _cage_edges: Array[MeshInstance3D] = []
var _edge_materials: Array[StandardMaterial3D] = []
var _crystal_base_y: float = 0.0
var _fading: bool = false
var _fade_progress: float = 0.0

# Timed lease — when lease_s > 0 the pedestal survives the pickup: the
# cage fades and hides instead of queue_free, and re-materializes with a
# fresh crystal once the lease (plus a grace beat) has run out. The
# crystal's dissolve is driven by CatalystCapabilityManager's clock; this
# countdown is the pedestal's own, started at pickup, so the return works
# even though the crystal may dissolve in a different map.
const RETURN_GRACE := 1.5       # seconds after lease end before the cage returns
var _lease_s: float = 0.0
var _leased_out: bool = false
var _return_left: float = 0.0
var _last_crystal_cfg: Dictionary = {}   # re-applied to the respawned crystal

signal catalyst_taken()
signal catalyst_returned()

func _ready() -> void:
	_build_cage()
	_build_light()
	_spawn_crystal()

func _process(delta: float) -> void:
	# Crystal hover and spin
	if is_instance_valid(_crystal) and not _fading:
		var bob := sin(Time.get_ticks_msec() / 1000.0 * CRYSTAL_BOB_SPEED) * CRYSTAL_BOB_AMOUNT
		_crystal.position.y = _crystal_base_y + bob
		_crystal.rotation.y += CRYSTAL_SPIN_SPEED * delta

	# Light pulse
	if _cage_light and not _fading:
		var pulse := 1.5 + sin(Time.get_ticks_msec() / 800.0) * 0.4
		_cage_light.light_energy = pulse

	# Cage fade after crystal is taken
	if _fading:
		_fade_progress += delta / CAGE_FADE_TIME
		if _fade_progress >= 1.0:
			if _lease_s > 0.0:
				# Leased crystal: the pedestal stays, hidden, awaiting return.
				_fading = false
				_leased_out = true
				if _cage:
					_cage.visible = false
				if _cage_light:
					_cage_light.visible = false
			else:
				queue_free()
			return
		var alpha := 1.0 - _fade_progress
		for mat in _edge_materials:
			mat.albedo_color.a = alpha * 0.8
			mat.emission_energy_multiplier = (1.0 - _fade_progress) * 2.0
		if _cage_light:
			_cage_light.light_energy = (1.0 - _fade_progress) * 1.5

	# Timed-lease return countdown (ticks through fade + hidden states).
	if _return_left > 0.0:
		_return_left -= delta
		if _return_left <= 0.0:
			_rematerialize()


# ═══════════════════════════════════════════════════════════════════════════
# CAGE — 12 wireframe edges of a 1m cube
# ═══════════════════════════════════════════════════════════════════════════

func _build_cage() -> void:
	_cage = Node3D.new()
	_cage.name = "Cage"
	add_child(_cage)

	var half := CAGE_SIZE * 0.5

	# 8 vertices of the cube, centered at origin, base at y=0
	var v := [
		Vector3(-half, 0.0,  -half),  # 0: bottom-back-left
		Vector3( half, 0.0,  -half),  # 1: bottom-back-right
		Vector3( half, 0.0,   half),  # 2: bottom-front-right
		Vector3(-half, 0.0,   half),  # 3: bottom-front-left
		Vector3(-half, CAGE_SIZE, -half),  # 4: top-back-left
		Vector3( half, CAGE_SIZE, -half),  # 5: top-back-right
		Vector3( half, CAGE_SIZE,  half),  # 6: top-front-right
		Vector3(-half, CAGE_SIZE,  half),  # 7: top-front-left
	]

	# 12 edges
	var edges := [
		[v[0], v[1]], [v[1], v[2]], [v[2], v[3]], [v[3], v[0]],  # bottom
		[v[4], v[5]], [v[5], v[6]], [v[6], v[7]], [v[7], v[4]],  # top
		[v[0], v[4]], [v[1], v[5]], [v[2], v[6]], [v[3], v[7]],  # verticals
	]

	for i in edges.size():
		var edge: Array = edges[i]
		var start: Vector3 = edge[0]
		var end_pos: Vector3 = edge[1]
		_build_edge(start, end_pos, i)


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
	_cage_edges.append(mesh_inst)
	_edge_materials.append(mat)

	# Position at midpoint and rotate to align cylinder with edge direction
	mesh_inst.position = mid
	# Cylinder default axis is Y. Rotate to align with edge direction.
	if dir.is_equal_approx(Vector3.UP) or dir.is_equal_approx(Vector3.DOWN):
		pass  # Already aligned
	else:
		var up := Vector3.UP
		var axis := up.cross(dir).normalized()
		var angle := up.angle_to(dir)
		if axis.length() > 0.001:
			mesh_inst.transform.basis = Basis(axis, angle)
			mesh_inst.position = mid


# ═══════════════════════════════════════════════════════════════════════════
# LIGHT — soft glow from the center
# ═══════════════════════════════════════════════════════════════════════════

func _build_light() -> void:
	_cage_light = OmniLight3D.new()
	_cage_light.name = "CageLight"
	_cage_light.light_color = Color(0.4, 0.7, 1.0)
	_cage_light.light_energy = 1.5
	_cage_light.omni_range = 2.0
	_cage_light.omni_attenuation = 1.5
	_cage_light.position = Vector3(0, CAGE_SIZE * 0.5, 0)
	add_child(_cage_light)


# ═══════════════════════════════════════════════════════════════════════════
# CRYSTAL — spawn the catalyst inside the cage
# ═══════════════════════════════════════════════════════════════════════════

func _spawn_crystal() -> void:
	var catalyst_scene := load("res://commons/hazards/becoming_catalyst/becoming_catalyst.tscn")
	if catalyst_scene == null:
		push_error("[CatalystPedestal] Failed to load becoming_catalyst.tscn")
		return

	_crystal = catalyst_scene.instantiate()
	_crystal.name = "CatalystCrystal"

	# Position at center of the cage
	_crystal_base_y = CAGE_SIZE * 0.5
	_crystal.position = Vector3(0, _crystal_base_y, 0)

	add_child(_crystal)

	# Connect to the catalyst's picked_up signal to know when player takes it
	if _crystal.has_signal("picked_up"):
		_crystal.picked_up.connect(_on_crystal_taken)

	# If apply_grid_config landed before _ready, forward the stashed
	# crystal config now that the crystal exists.
	if not _pending_crystal_cfg.is_empty() and _crystal.has_method("apply_grid_config"):
		_crystal.call_deferred("apply_grid_config", _pending_crystal_cfg)
		_pending_crystal_cfg = {}

	print("[CatalystPedestal] Crystal spawned at center of cage")


func _on_crystal_taken(_pickable) -> void:
	# Crystal has been grabbed — fade the cage away
	_fading = true
	_fade_progress = 0.0
	catalyst_taken.emit()
	if _lease_s > 0.0:
		# Start the return countdown. The crystal dissolves on the
		# manager's clock (~lease_s after absorb); the cage returns a
		# grace beat later so the two never overlap.
		_return_left = _lease_s + RETURN_GRACE
		print("[CatalystPedestal] Crystal taken on a %.0fs lease — return countdown started" % _lease_s)
	else:
		print("[CatalystPedestal] Crystal taken — fading cage")


## Lease over: restore the cage and grow a fresh crystal with the same
## config the original had (sequence binding, lease, mode seeds).
func _rematerialize() -> void:
	_return_left = 0.0
	_leased_out = false
	_fading = false
	_fade_progress = 0.0
	if _cage:
		_cage.visible = true
	for mat in _edge_materials:
		mat.albedo_color.a = 0.8
		mat.emission_energy_multiplier = 2.0
	if _cage_light:
		_cage_light.visible = true
		_cage_light.light_energy = 1.5
	_pending_crystal_cfg = _last_crystal_cfg.duplicate()
	_spawn_crystal()
	catalyst_returned.emit()
	print("[CatalystPedestal] Lease over — cage re-materialized, crystal returned")


# ═══════════════════════════════════════════════════════════════════════════
# GRID INTEGRATION
# ═══════════════════════════════════════════════════════════════════════════

# Stash for crystal config when apply_grid_config arrives before _ready.
var _pending_crystal_cfg: Dictionary = {}

# Token grammar: catalyst_pedestal:0:0#key:value#key:value...
# Forwarded keys (handled by becoming_catalyst.configure):
#   all_modes      — unlock every mode (debug)
#   start_mode     — unlock one specific mode
#   unlock_to      — unlock all modes up to a given order
#   shooting_only  — unlock only order >= 1 (skip voxel/wedge placement)
#   active_mode    — set current_mode_index to point at this mode_id
#   sequence       — bind the crystal to a sequence (name or "auto"); arms
#                    the native mode via catalyst_sequence_binding.gd
#   lease_s        — timed lease: crystal dissolves after N seconds and the
#                    pedestal re-materializes it (also pedestal-handled)
# Pedestal-handled keys:
#   cage_color     — RGBA wireframe tint
#   clear_modes    — call CatalystCapabilityManager.reset_progression() first
const _CATALYST_FORWARD_KEYS = [
	"all_modes", "start_mode", "unlock_to",
	"shooting_only", "active_mode", "sequence", "lease_s",
]


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("cage_color"):
		var c: Color = Color(config_data["cage_color"])
		for mat in _edge_materials:
			mat.albedo_color = c
			mat.emission = c

	# clear_modes: only free GHOST catalysts (auto-absorbed onto an
	# XRController by the manager from save state). Don't touch the
	# pedestal's own crystal or the bracelet. Most maps will only have
	# our pedestal's crystal in the scene, so this is a no-op there.
	if _is_truthy(config_data.get("clear_modes", false)):
		var freed: int = 0
		for cat in get_tree().get_nodes_in_group("catalyst"):
			# Skip our pedestal's own crystal (and any descendant of it).
			if cat == _crystal or self.is_ancestor_of(cat):
				continue
			# Only free if parented to an XRController3D — that's what
			# auto_absorb does. Anything else (pedestals in other maps,
			# sibling catalysts, etc.) leave alone.
			var p := cat.get_parent()
			if p and p.get_class() == "XRController3D":
				cat.queue_free()
				freed += 1

		var cap_mgr := get_tree().root.get_node_or_null("CatalystCapabilityManager")
		if cap_mgr == null:
			cap_mgr = get_tree().root.get_node_or_null("CatalystCapability")
		if cap_mgr and "_catalyst_modes" in cap_mgr:
			cap_mgr._catalyst_modes.clear()
			if cap_mgr.has_method("save_state"):
				cap_mgr.call("save_state")
		print("[CatalystPedestal] clear_modes ran — freed %d ghost catalysts; bracelet preserved" % freed)

	# lease_s: the pedestal needs it too (return countdown + survive fade).
	if config_data.has("lease_s"):
		_lease_s = float(str(config_data["lease_s"]))

	# Forward catalyst-related keys to the spawned crystal.
	var crystal_cfg: Dictionary = {}
	for k in _CATALYST_FORWARD_KEYS:
		if config_data.has(k):
			crystal_cfg[k] = config_data[k]
	if crystal_cfg.is_empty():
		return
	# Remember for lease respawns — the returned crystal gets the same
	# sequence binding / lease / mode seeds the original had.
	_last_crystal_cfg = crystal_cfg.duplicate()
	if is_instance_valid(_crystal) and _crystal.has_method("apply_grid_config"):
		_crystal.call("apply_grid_config", crystal_cfg)
		_pending_crystal_cfg = {}
	else:
		# Crystal not yet spawned — defer until _spawn_crystal runs.
		_pending_crystal_cfg = crystal_cfg


# Truthy check — accepts native bool, "true"/"yes"/"1" strings, non-zero numbers.
# GDScript has no bool() constructor; tokens arrive as strings via the parser.
func _is_truthy(value) -> bool:
	if typeof(value) == TYPE_BOOL:
		return value
	if typeof(value) == TYPE_STRING:
		return value.to_lower() in ["true", "1", "yes"]
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		return value != 0
	return false
