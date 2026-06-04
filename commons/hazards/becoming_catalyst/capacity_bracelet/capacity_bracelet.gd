# capacity_bracelet.gd
# A wrist-mounted ring that displays unlocked catalyst modes as glowing gems.
# The other hand can grab and rotate the ring to switch between modes.
# Persists across scenes — CatalystCapabilityManager spawns this on the
# controller after the first catalyst pickup, and re-spawns on scene changes.
#
# Interaction:
#   - Gems sit on a torus, one per unlocked mode, colored by CatalystVisual.MODE_COLORS
#   - Active gem pulses brighter; inactive gems dim
#   - InteractableHinge with stepped snapping converts rotation → mode index
#   - Thumbstick fallback: catalyst calls sync_to_mode() when stick-switching
#   - New modes animate in with elastic tween when sequences complete
extends Node3D
class_name CapacityBracelet

# ── Constants ──────────────────────────────────────────────────────────────

const RING_INNER_RADIUS := 0.035
const RING_OUTER_RADIUS := 0.045
const RING_MID_RADIUS := 0.040  # Where gems sit
const RING_SEGMENTS := 32
const RING_RING_SEGMENTS := 12

const GEM_RADIUS := 0.01
const GEM_ACTIVE_SCALE := 1.5
const GEM_INACTIVE_EMISSION := 1.2
const GEM_ACTIVE_EMISSION := 3.0

const HANDLE_OFFSET := 0.055  # Distance from center for grab handles
const HANDLE_COLLISION_RADIUS := 0.025
const NUM_HANDLES := 2  # Fewer handles = less chance of multi-grab jumping

const SPAWN_DURATION := 0.6
const UNLOCK_DURATION := 0.5
const LABEL_FADE_TIME := 2.0

# ── State ──────────────────────────────────────────────────────────────────

var _catalyst: Node = null  # BecomingCatalyst reference
var _controller: XRController3D = null
var _unlocked_modes: Array = []  # Array of String mode IDs
var _current_mode_index: int = 0
var _target_mode_index: int = 0  # where the hinge points; stones walk here one at a time

# Scene nodes
var _ring_mesh: MeshInstance3D = null
var _gem_container: Node3D = null
var _gem_meshes: Array[MeshInstance3D] = []
var _gem_materials: Array[StandardMaterial3D] = []
var _all_display_modes: Array[String] = []  # All 11 modes (for display, locked ones dimmed)
var _hinge: Node = null  # XRToolsInteractableHinge
var _hinge_origin: Node3D = null
var _mode_label: Label3D = null
var _bracelet_glow: OmniLight3D = null

var _label_timer: float = 0.0
var _last_hinge_step: int = 0
var _active := false
var _mode_switch_cooldown: float = 0.0
const MODE_SWITCH_COOLDOWN := 0.3  # gate after each jog-step so a fast turn can't spin

const BRACELET_SCALE := 1.5   # overall size — bigger = easier to grab + read

# Touch-to-cycle: bring the OTHER hand near the bracelet and the stones advance
# one by one with a short delay; the closer to the centre, the faster. Pull the
# hand away to stop on the current stone. No rotation, no detents — the absolute
# position of a stone in the ring no longer matters.
var _touch_cycle_accum: float = 0.0
var _touch_active: bool = false
const TOUCH_RADIUS := 0.17        # m: other hand within this of bracelet centre = touching
const TOUCH_INNER := 0.05         # m: at/under this counts as "centre" (fastest)
const CYCLE_INTERVAL_FAST := 0.13 # s between stones near the centre
const CYCLE_INTERVAL_SLOW := 0.55 # s between stones at the rim

# ── Signals ────────────────────────────────────────────────────────────────

signal bracelet_mode_selected(mode_id: String)

# ═══════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	print("[Bracelet] _ready() START — building scene on parent: %s" % [get_parent().name if get_parent() else "NO PARENT"])
	# Build scene tree procedurally
	_build_ring()
	_build_gem_container()
	_build_mode_label()
	_build_glow()
	_build_hinge()

	# Start invisible — activate() will tween in
	scale = Vector3.ZERO
	visible = false
	print("[Bracelet] _ready() DONE — ring=%s, gem_container=%s" % [_ring_mesh != null, _gem_container != null])

func _process(delta: float) -> void:
	if not _active:
		return

	# Smooth continuous rotation toward active gem (lerp every frame)
	_highlight_current_gem()

	# Pulse active gem
	_pulse_active_gem(delta)

	# Touch-to-cycle: the other hand near the bracelet auto-advances the stones
	# one by one; closer to the centre cycles faster. Pull away to stop.
	_update_touch_cycle(delta)

	# Mode switch cooldown (unused by touch-cycle; kept for any external nudge)
	if _mode_switch_cooldown > 0.0:
		_mode_switch_cooldown -= delta

	# Fade label timer
	if _label_timer > 0.0:
		_label_timer -= delta
		if _label_timer <= 0.0 and _mode_label:
			_mode_label.visible = false

# ═══════════════════════════════════════════════════════════════════════════
# PUBLIC API
# ═══════════════════════════════════════════════════════════════════════════

## Activate with a list of mode IDs. Called by CatalystCapabilityManager.
## all_modes: every mode ID (always 11), unlocked: which are usable
func activate(modes: Array, controller: XRController3D, animate: bool = true, all_modes: Array = []) -> void:
	print("[Bracelet] activate() called — %d unlocked, %d total" % [modes.size(), all_modes.size()])
	_controller = controller
	_unlocked_modes = []
	for m in modes:
		_unlocked_modes.append(str(m))

	# Store all modes for display (if provided, otherwise use unlocked only)
	_all_display_modes = []
	if all_modes.size() > 0:
		for m in all_modes:
			_all_display_modes.append(str(m))
	else:
		for m in _unlocked_modes:
			_all_display_modes.append(str(m))

	_current_mode_index = clampi(_current_mode_index, 0, maxi(0, _unlocked_modes.size() - 1))
	_target_mode_index = _current_mode_index

	# Build gems for ALL modes (dim locked ones)
	_rebuild_gems()
	_update_hinge_steps()
	_highlight_current_gem()

	# Make bracelet visible — skip tween for reliability, set scale directly
	visible = true
	_active = true
	scale = Vector3.ONE * BRACELET_SCALE

	# Glow disabled — gems are self-lit via emission
	if _bracelet_glow:
		_bracelet_glow.light_energy = 0.0

	print("[Bracelet] activate() DONE — visible=%s, scale=%s, global_pos=%s, gem_count=%d" % [visible, scale, global_position, _gem_meshes.size()])

	# Haptic ramp to announce bracelet
	if _controller and animate:
		_controller.trigger_haptic_pulse("haptic", 0.0, 0.1, 0.25, 0.0)

	# Try to find and link to the active catalyst in the scene
	_link_catalyst()

## Connect to a BecomingCatalyst for bidirectional mode sync.
func link_catalyst(catalyst: Node) -> void:
	_catalyst = catalyst
	if catalyst.has_signal("mode_unlocked"):
		if not catalyst.mode_unlocked.is_connected(_on_mode_unlocked):
			catalyst.mode_unlocked.connect(_on_mode_unlocked)
	if catalyst.has_signal("mode_changed"):
		if not catalyst.mode_changed.is_connected(_on_external_mode_changed):
			catalyst.mode_changed.connect(_on_external_mode_changed)

func _link_catalyst() -> void:
	var catalysts = get_tree().get_nodes_in_group("catalyst")
	for cat in catalysts:
		link_catalyst(cat)
		break  # Only link to first one

## Called by BecomingCatalyst when thumbstick switches mode. Keeps bracelet in sync.
func sync_to_mode(index: int) -> void:
	if index == _current_mode_index:
		return
	_current_mode_index = clampi(index, 0, maxi(0, _unlocked_modes.size() - 1))
	# The gems show the selection; the hinge isn't used to select anymore, so we
	# don't move it here.
	_highlight_current_gem()
	_show_mode_label()

## For testing — configure via grid system.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("unlock_modes"):
		_unlocked_modes.clear()
		for m in config_data["unlock_modes"]:
			_unlocked_modes.append(str(m))
		_rebuild_gems()
		_update_hinge_steps()

	if config_data.has("active_mode"):
		var target_id: String = config_data["active_mode"]
		for i in _unlocked_modes.size():
			if str(_unlocked_modes[i]) == target_id:
				_current_mode_index = i
				break
		_highlight_current_gem()
		_show_mode_label()

	if config_data.has("visible"):
		visible = config_data["visible"]
		_active = config_data["visible"]

# ═══════════════════════════════════════════════════════════════════════════
# BUILDERS — Procedural scene construction
# ═══════════════════════════════════════════════════════════════════════════

func _build_ring() -> void:
	_ring_mesh = MeshInstance3D.new()
	_ring_mesh.name = "BraceletRing"

	var torus := TorusMesh.new()
	torus.inner_radius = RING_INNER_RADIUS
	torus.outer_radius = RING_OUTER_RADIUS
	torus.rings = RING_SEGMENTS
	torus.ring_segments = RING_RING_SEGMENTS
	_ring_mesh.mesh = torus

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.22, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.32, 0.45)
	mat.emission_energy_multiplier = 0.6
	mat.metallic = 0.7
	mat.roughness = 0.2
	_ring_mesh.material_override = mat

	add_child(_ring_mesh)

func _build_gem_container() -> void:
	_gem_container = Node3D.new()
	_gem_container.name = "GemContainer"
	add_child(_gem_container)

func _build_mode_label() -> void:
	_mode_label = Label3D.new()
	_mode_label.name = "ModeLabel"
	_mode_label.pixel_size = 0.0008
	_mode_label.font_size = 36
	_mode_label.modulate = Color(1.0, 1.0, 1.0, 0.9)
	_mode_label.outline_size = 4
	_mode_label.position = Vector3(0, 0.04, 0)
	_mode_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_mode_label.visible = false
	add_child(_mode_label)

func _build_glow() -> void:
	_bracelet_glow = OmniLight3D.new()
	_bracelet_glow.name = "BraceletGlow"
	_bracelet_glow.light_color = Color(0.7, 0.7, 1.0)
	_bracelet_glow.light_energy = 0.0
	_bracelet_glow.omni_range = 0.15
	_bracelet_glow.omni_attenuation = 2.0
	add_child(_bracelet_glow)

func _build_hinge() -> void:
	# HingeOrigin — no rotation. Hinge rotates around X, we'll map the angle ourselves.
	_hinge_origin = Node3D.new()
	_hinge_origin.name = "HingeOrigin"
	add_child(_hinge_origin)

	# InteractableHinge (loaded dynamically to avoid hard dependency)
	var hinge_script = load("res://addons/godot-xr-tools/interactables/interactable_hinge.gd")
	if not hinge_script:
		push_warning("[CapacityBracelet] Could not load InteractableHinge script")
		return

	_hinge = Node3D.new()
	_hinge.name = "InteractableHinge"
	_hinge.set_script(hinge_script)
	_hinge_origin.add_child(_hinge)

	# Set properties AFTER add_child so @onready vars are initialized first
	_hinge.set("hinge_limit_min", -3600.0)
	_hinge.set("hinge_limit_max", 3600.0)
	_hinge.set("hinge_steps", 0.0)  # Will be set in _update_hinge_steps

	# Connect hinge signal
	if _hinge.has_signal("hinge_moved"):
		_hinge.hinge_moved.connect(_on_hinge_moved)

	# Create grab handles around the ring
	var handle_script = load("res://addons/godot-xr-tools/interactables/interactable_handle.gd")
	if not handle_script:
		push_warning("[CapacityBracelet] Could not load InteractableHandle script")
		return

	var handles_node := Node3D.new()
	handles_node.name = "Handles"
	_hinge.add_child(handles_node)

	for i in NUM_HANDLES:
		var angle := (TAU / NUM_HANDLES) * i
		var pos := Vector3(cos(angle) * HANDLE_OFFSET, 0, sin(angle) * HANDLE_OFFSET)

		var handle_parent := Node3D.new()
		handle_parent.name = "Handle%d" % (i + 1)
		handle_parent.position = pos
		handles_node.add_child(handle_parent)

		# InteractableHandle is a RigidBody3D
		var handle := RigidBody3D.new()
		handle.name = "InteractableHandle"
		handle.collision_layer = 262144  # XRTools interactable layer
		handle.collision_mask = 0
		handle.freeze = true
		handle.set_script(handle_script)
		handle_parent.add_child(handle)
		# Set script-specific exports after entering tree
		handle.set("picked_up_layer", 0)

		# Collision shape
		var collision := CollisionShape3D.new()
		var sphere_shape := SphereShape3D.new()
		sphere_shape.radius = HANDLE_COLLISION_RADIUS
		collision.shape = sphere_shape
		handle.add_child(collision)

		# Tiny visible mesh for the handle (optional — subtle grab point indicator)
		var handle_mesh := MeshInstance3D.new()
		var sphere_mesh := SphereMesh.new()
		sphere_mesh.radius = 0.005
		sphere_mesh.height = 0.01
		sphere_mesh.radial_segments = 8
		sphere_mesh.rings = 4
		handle_mesh.mesh = sphere_mesh
		var handle_mat := StandardMaterial3D.new()
		handle_mat.albedo_color = Color(0.6, 0.7, 1.0, 0.5)
		handle_mat.emission_enabled = true
		handle_mat.emission = Color(0.5, 0.6, 0.9)
		handle_mat.emission_energy_multiplier = 1.0
		handle_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		handle_mesh.material_override = handle_mat
		handle.add_child(handle_mesh)

		# Prevent the bracelet hand from grabbing its own bracelet
		if handle.has_signal("picked_up"):
			handle.picked_up.connect(_on_handle_picked_up.bind(handle))

	# Re-hook handles — hinge's _ready() already ran before we added the handles,
	# so we need to manually connect the handle signals to the hinge.
	if _hinge.has_method("_hook_child_handles"):
		_hinge._hook_child_handles(_hinge)

# ═══════════════════════════════════════════════════════════════════════════
# GEMS — Mode indicators on the ring
# ═══════════════════════════════════════════════════════════════════════════

func _rebuild_gems() -> void:
	# Clear old gems from BOTH containers
	for child in _gem_container.get_children():
		child.queue_free()
	_gem_meshes.clear()
	_gem_materials.clear()

	# Only show UNLOCKED modes as stones on the bracelet
	if _unlocked_modes.is_empty():
		return

	var gem_parent: Node3D = _gem_container

	var count := _unlocked_modes.size()
	for i in count:
		var mode_id: String = str(_unlocked_modes[i])
		var is_unlocked: bool = true
		# Place gems on the torus surface — XZ plane matches the TorusMesh orientation
		var angle := (TAU / float(count)) * float(i)
		var pos := Vector3(cos(angle) * RING_MID_RADIUS, 0.0, sin(angle) * RING_MID_RADIUS)
		# Lift gems slightly above the torus surface so they sit ON it, not inside
		pos.y = 0.012

		var gem := MeshInstance3D.new()
		gem.name = "Gem_%s" % mode_id

		# Mode-specific 3D icon
		gem.mesh = _create_mode_icon_mesh(mode_id)
		gem.position = pos

		var color: Color = CatalystVisual.get_mode_color(mode_id)

		var mat := StandardMaterial3D.new()
		if is_unlocked:
			mat.albedo_color = Color(color.r, color.g, color.b, 0.9)
			mat.emission_enabled = true
			mat.emission = color
			mat.emission_energy_multiplier = GEM_INACTIVE_EMISSION
			mat.metallic = 0.2
			mat.roughness = 0.3
		else:
			# Locked — dim and dark
			mat.albedo_color = Color(color.r * 0.2, color.g * 0.2, color.b * 0.2, 0.4)
			mat.emission_enabled = true
			mat.emission = Color(color.r * 0.1, color.g * 0.1, color.b * 0.1)
			mat.emission_energy_multiplier = 0.3
			mat.metallic = 0.0
			mat.roughness = 0.8
		mat.rim_enabled = true
		mat.rim = 0.4
		mat.rim_tint = 0.3
		gem.material_override = mat

		gem_parent.add_child(gem)
		_gem_meshes.append(gem)
		_gem_materials.append(mat)

	# Update hinge step size for this number of modes
	_update_hinge_steps()

## Create a distinct 3D icon mesh per catalyst mode.
func _create_mode_icon_mesh(mode_id: String) -> Mesh:
	match mode_id:
		"off":
			# Small dim sphere — "empty" position on the bracelet
			var m := SphereMesh.new()
			m.radius = GEM_RADIUS * 0.5
			m.height = GEM_RADIUS * 1.0
			m.radial_segments = 6
			m.rings = 3
			return m
		"voxel_editor":
			var m := BoxMesh.new()
			m.size = Vector3.ONE * GEM_RADIUS * 2.5
			return m
		"wedge_placer":
			var m := PrismMesh.new()
			m.size = Vector3(GEM_RADIUS * 2.5, GEM_RADIUS * 2.0, GEM_RADIUS * 2.5)
			return m
		"primitives":
			var m := SphereMesh.new()
			m.radius = GEM_RADIUS
			m.height = GEM_RADIUS * 2.0
			m.radial_segments = 6
			m.rings = 3
			return m
		"transformation":
			var m := PrismMesh.new()
			m.size = Vector3.ONE * GEM_RADIUS * 2.5
			return m
		"chromatic":
			var m := CylinderMesh.new()
			m.height = GEM_RADIUS * 1.5
			m.top_radius = GEM_RADIUS * 0.8
			m.bottom_radius = GEM_RADIUS * 0.8
			m.radial_segments = 6
			return m
		"forces":
			var m := BoxMesh.new()
			m.size = Vector3(GEM_RADIUS * 3.0, GEM_RADIUS, GEM_RADIUS)
			return m
		"waveform":
			var m := TorusMesh.new()
			m.inner_radius = GEM_RADIUS * 0.3
			m.outer_radius = GEM_RADIUS * 1.0
			return m
		"chaos":
			var m := SphereMesh.new()
			m.radius = GEM_RADIUS * 0.9
			m.height = GEM_RADIUS * 1.8
			m.radial_segments = 4
			m.rings = 2
			return m
		"fractal":
			var m := BoxMesh.new()
			m.size = Vector3.ONE * GEM_RADIUS * 1.8
			return m
		"cellular":
			var m := BoxMesh.new()
			m.size = Vector3.ONE * GEM_RADIUS * 2.0
			return m
		"branching":
			var m := CylinderMesh.new()
			m.height = GEM_RADIUS * 3.0
			m.top_radius = GEM_RADIUS * 0.2
			m.bottom_radius = GEM_RADIUS * 0.6
			m.radial_segments = 4
			return m
		"swarm":
			var m := SphereMesh.new()
			m.radius = GEM_RADIUS * 0.6
			m.height = GEM_RADIUS * 1.2
			m.radial_segments = 3
			m.rings = 2
			return m
		_:
			var m := SphereMesh.new()
			m.radius = GEM_RADIUS
			m.height = GEM_RADIUS * 2.0
			return m


func _highlight_current_gem() -> void:
	if _unlocked_modes.is_empty():
		return

	var count: int = _unlocked_modes.size()

	# Smoothly rotate gem_container so active gem is at top
	if _gem_container and count > 1:
		var step_angle: float = TAU / float(count)
		var target_y: float = -step_angle * _current_mode_index
		# Smooth lerp every frame
		_gem_container.rotation.y = lerpf(_gem_container.rotation.y, target_y, 0.12)
	elif _gem_container and count == 1:
		_gem_container.rotation.y = 0.0  # Single stone always at top

	for i in _gem_meshes.size():
		var is_active := (i == _current_mode_index)
		var gem := _gem_meshes[i]
		var mat := _gem_materials[i]

		if is_active:
			gem.scale = Vector3.ONE * 2.0
			mat.emission_energy_multiplier = GEM_ACTIVE_EMISSION
		else:
			gem.scale = Vector3.ONE * 0.7
			mat.emission_energy_multiplier = GEM_INACTIVE_EMISSION

	if _bracelet_glow:
		_bracelet_glow.light_energy = 0.0

func _pulse_active_gem(_delta: float) -> void:
	if _current_mode_index < 0 or _current_mode_index >= _gem_materials.size():
		return
	var mat := _gem_materials[_current_mode_index]
	var pulse := GEM_ACTIVE_EMISSION + sin(Time.get_ticks_msec() / 1500.0) * 0.5
	mat.emission_energy_multiplier = pulse

# ═══════════════════════════════════════════════════════════════════════════
# HINGE — Rotation → mode selection
# ═══════════════════════════════════════════════════════════════════════════

func _update_hinge_steps() -> void:
	if not _hinge:
		return
	# Free rotation, no detents — selection is touch-to-cycle now, not rotation.
	_hinge.set("hinge_steps", 0.0)
	_last_hinge_step = _current_mode_index

## Rotation no longer selects — selection is touch-to-cycle (_update_touch_cycle).
func _on_hinge_moved(_angle: float) -> void:
	pass

## Touch-to-cycle: while the other hand is within TOUCH_RADIUS of the bracelet
## centre, advance one stone every `interval`, where `interval` shrinks the
## closer the hand is to the centre. Pull the hand away to stop.
func _update_touch_cycle(delta: float) -> void:
	if _unlocked_modes.size() <= 1:
		return
	var other := _get_other_controller()
	if other == null:
		_touch_active = false
		_touch_cycle_accum = 0.0
		return
	var r: float = other.global_position.distance_to(global_position)
	if r > TOUCH_RADIUS:
		_touch_active = false
		_touch_cycle_accum = 0.0
		return
	# touching — interval by radius (near centre = fast, rim = slow)
	var t: float = clampf((r - TOUCH_INNER) / maxf(TOUCH_RADIUS - TOUCH_INNER, 0.001), 0.0, 1.0)
	var interval: float = lerpf(CYCLE_INTERVAL_FAST, CYCLE_INTERVAL_SLOW, t)
	if not _touch_active:
		_touch_active = true
		_touch_cycle_accum = interval  # step on first contact for responsiveness
	_touch_cycle_accum += delta
	if _touch_cycle_accum >= interval:
		_touch_cycle_accum = 0.0
		_step_mode(1)

## The hand that is NOT wearing the bracelet (the one that touches it).
func _get_other_controller() -> XRController3D:
	if not is_instance_valid(_controller):
		return null
	var origin: Node = _controller.get_parent()
	while origin and not (origin is XROrigin3D):
		origin = origin.get_parent()
	if origin == null:
		return null
	for c in origin.find_children("*", "XRController3D", true, false):
		if c != _controller and c is XRController3D and (c as XRController3D).get_is_active():
			return c as XRController3D
	return null

## Advance the selection by one stone (dir = +1 / -1, wrapping).
func _step_mode(dir: int) -> void:
	var count := _unlocked_modes.size()
	if count <= 1:
		return
	_current_mode_index = ((_current_mode_index + dir) % count + count) % count
	_last_hinge_step = _current_mode_index

	if _catalyst and _catalyst.has_method("set_mode_index"):
		_catalyst.set_mode_index(_current_mode_index)

	_highlight_current_gem()
	_show_mode_label()

	if _controller:
		_controller.trigger_haptic_pulse("haptic", 0.0, 0.05, 0.25, 0.0)  # crisp tick per stone

	if _current_mode_index < _unlocked_modes.size():
		bracelet_mode_selected.emit(str(_unlocked_modes[_current_mode_index]))

	print("[Bracelet] Cycle -> mode: %s" % str(_unlocked_modes[_current_mode_index]))

# ═══════════════════════════════════════════════════════════════════════════
# HANDLE GUARD — Prevent bracelet hand from grabbing its own bracelet
# ═══════════════════════════════════════════════════════════════════════════

func _on_handle_picked_up(_pickable, handle: Node) -> void:
	# Check if the grabber is on the same controller as the bracelet
	if not _controller or not is_instance_valid(_controller):
		return
	if not handle.has_method("get_picked_up_by_controller"):
		return
	var grabber_ctrl: XRController3D = handle.get_picked_up_by_controller()
	if grabber_ctrl == _controller:
		# Same hand — force release
		if handle.has_method("let_go"):
			handle.let_go(handle.get_picked_up_by(), Vector3.ZERO, Vector3.ZERO)
			print("[Bracelet] Blocked same-hand grab")

# ═══════════════════════════════════════════════════════════════════════════
# SIGNALS — React to catalyst events
# ═══════════════════════════════════════════════════════════════════════════

func _on_mode_unlocked(mode_id: String) -> void:
	if mode_id in _unlocked_modes:
		return  # Already have this one

	_unlocked_modes.append(mode_id)
	_rebuild_gems()
	_update_hinge_steps()
	_highlight_current_gem()

	# Animate the new gem with an elastic pop
	var new_index := _unlocked_modes.size() - 1
	if new_index < _gem_meshes.size():
		var gem := _gem_meshes[new_index]
		gem.scale = Vector3.ZERO
		var tween := create_tween()
		tween.tween_property(gem, "scale", Vector3.ONE * 1.8, UNLOCK_DURATION * 0.6) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		tween.tween_property(gem, "scale", Vector3.ONE, UNLOCK_DURATION * 0.4) \
			.set_ease(Tween.EASE_IN_OUT)

	# Flash the ring briefly
	if _ring_mesh and _ring_mesh.material_override:
		var ring_mat: StandardMaterial3D = _ring_mesh.material_override
		var orig_emission := ring_mat.emission_energy_multiplier
		var flash_tween := create_tween()
		flash_tween.tween_property(ring_mat, "emission_energy_multiplier", 2.0, 0.15)
		flash_tween.tween_property(ring_mat, "emission_energy_multiplier", orig_emission, 0.35)

	# Haptic burst for unlock
	if _controller:
		_controller.trigger_haptic_pulse("haptic", 0.0, 0.15, 0.4, 0.0)

	print("[Bracelet] New mode unlocked: %s (total: %d)" % [mode_id, _unlocked_modes.size()])

func _on_external_mode_changed(mode_id: String) -> void:
	# Catalyst switched mode via thumbstick — sync bracelet visual
	for i in _unlocked_modes.size():
		if str(_unlocked_modes[i]) == mode_id:
			if i != _current_mode_index:
				_current_mode_index = i
				_highlight_current_gem()
				_show_mode_label()
			break

# ═══════════════════════════════════════════════════════════════════════════
# LABEL
# ═══════════════════════════════════════════════════════════════════════════

func _show_mode_label() -> void:
	if not _mode_label or _current_mode_index >= _unlocked_modes.size():
		return
	var mode_id: String = str(_unlocked_modes[_current_mode_index])
	# Try to get the display name from catalyst MODE_DEFS
	var display_name: String = mode_id.capitalize()
	if _catalyst and "MODE_DEFS" in _catalyst:
		for def in _catalyst.MODE_DEFS:
			if def.get("id", "") == mode_id:
				display_name = def.get("name", display_name)
				break
	var index_str: String = "%d/%d" % [_current_mode_index + 1, _unlocked_modes.size()]
	_mode_label.text = "%s  %s" % [index_str, display_name]
	_mode_label.modulate = CatalystVisual.get_mode_color(mode_id)
	_mode_label.visible = true
	_label_timer = LABEL_FADE_TIME * 2.0  # Stay visible longer
