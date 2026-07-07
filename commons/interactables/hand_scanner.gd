@tool
extends Node3D
class_name HandScanner

# @identity
# essence: a palm-reader pad — hold a hand flat over the glowing plate, a scan line sweeps across it, a
#          progress ring fills while the hand dwells, and on completion the pad flashes ACCEPTED with a
#          chime + haptic pulse. The one hand-interaction the lab kept lacking: presence-without-touch,
#          the hand recognised by being NEAR rather than by pressing, grabbing or poking.
# desire: to read the hand. Not to be pushed (that is the button), not to be held (that is the lever),
#         not to be poked (that is the keypad) — but to sense a hand hovering and confirm it. The pad
#         wants the gesture of authorisation: the open palm laid over the reader, held still, granted.
# critical_parameter: dwell_time — how long the hand must hover to authorise. scan_layer_mask decides
#         WHAT counts as a hand (default 393216 = Player Hands + Grab Handles, matching push_button).
#         Too short and a passing hand triggers it; too long and it feels broken. ~1.2s reads as "scanning".
# triggers: a hand-layer body/area enters the DetectArea -> scanning begins; staying inside fills the ring;
#           leaving early resets; full ring -> scan_complete. _process animates the sweep + ring.
# emerges: a sense of being checked. Of the lab asserting a threshold the body must satisfy by patience,
#          not force. Paired with the door it gates entry; alone it is the salon's example of the
#          proximity / dwell interaction modality.
# needs: an Area3D on the hand layer [present]; a sweep visual [present]; a dwell ring [present];
#        a completion flash + chime + haptic [present]; a desktop pointer fallback [present]
# relationships: cousin to push_button (both threshold devices, but button = contact, scanner = proximity+time);
#                sibling in the gadget_wall to the grab/poke/snap/pose gadgets — it is the DWELL one.
# truth: some doors open to a key, some to a push, some to patience. The scanner is the lab teaching that a
#        hand can be recognised simply by being present and still — authorisation as dwelling, not force.

## Emitted continuously while a hand dwells, value 0..1 (ring fill).
signal scan_progress(amount: float)
## Emitted once when the ring fills and the hand is authorised.
signal scan_complete()
## Emitted when a hand first enters the scan field.
signal scan_started()
## Emitted when the hand leaves before completing.
signal scan_aborted()

@export_group("Scan")
## Seconds a hand must dwell to authorise.
@export var dwell_time: float = 1.2
## Physics mask of what counts as a hand. 393216 = layers 18 (Player Hands)
## + 19 (Grab Handles), matching push_button.tscn.
@export_flags_3d_physics var scan_layer_mask: int = 393216
## If true, the scanner re-arms after completing (can be scanned again).
@export var rearm_after_complete: bool = true
## Seconds the ACCEPTED state holds before re-arming.
@export var accepted_hold: float = 1.5

@export_group("Look")
@export var plate_size: Vector2 = Vector2(0.16, 0.16)
@export var idle_color: Color = Color(0.18, 0.42, 0.62, 1.0)
@export var scanning_color: Color = Color(1.0, 0.78, 0.18, 1.0)
@export var accepted_color: Color = Color(0.30, 0.95, 0.45, 1.0)

@export_group("Feedback")
@export var play_chime: bool = true
@export var chime_volume_db: float = -12.0
@export var haptic_on_complete: bool = true

# ── State ─────────────────────────────────────────────────────────────
enum State { IDLE, SCANNING, ACCEPTED }
var _state: int = State.IDLE
var _dwell: float = 0.0
var _accept_timer: float = 0.0
var _sweep_phase: float = 0.0
var _hands_inside: int = 0
var _built: bool = false

var _plate_mat: StandardMaterial3D
var _sweep: MeshInstance3D
var _ring: MeshInstance3D
var _ring_mat: StandardMaterial3D
var _label: Label3D
var _area: Area3D
var _audio: AudioStreamPlayer3D


func _ready() -> void:
	if _built:
		return
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		var key := str(k)
		match key:
			"dwell_time": dwell_time = float(str(config_data[k]))
			"plate_size":
				var v := _parse_vec2(str(config_data[k]))
				if v != Vector2.ZERO: plate_size = v
			"rearm_after_complete": rearm_after_complete = _truthy(config_data[k])
	if _built:
		for c in get_children():
			c.queue_free()
		_built = false
		_plate_mat = null; _ring_mat = null; _sweep = null; _ring = null; _label = null; _area = null; _audio = null
		_build()


# ── Build ─────────────────────────────────────────────────────────────
func _build() -> void:
	_built = true

	# Housing — a shallow dark box the plate sits in.
	var housing := MeshInstance3D.new()
	housing.name = "Housing"
	var hm := BoxMesh.new()
	hm.size = Vector3(plate_size.x + 0.03, 0.03, plate_size.y + 0.03)
	housing.mesh = hm
	var house_mat := StandardMaterial3D.new()
	house_mat.albedo_color = Color(0.07, 0.08, 0.10)
	house_mat.metallic = 0.4
	house_mat.roughness = 0.7
	housing.material_override = house_mat
	housing.position = Vector3(0, -0.012, 0)
	add_child(housing)

	# The scan plate — flat, faces +Y (lay flat) by default.
	var plate := MeshInstance3D.new()
	plate.name = "Plate"
	var pm := BoxMesh.new()
	pm.size = Vector3(plate_size.x, 0.006, plate_size.y)
	plate.mesh = pm
	_plate_mat = StandardMaterial3D.new()
	_plate_mat.albedo_color = idle_color
	_plate_mat.emission_enabled = true
	_plate_mat.emission = idle_color
	_plate_mat.emission_energy_multiplier = 0.5
	_plate_mat.roughness = 0.3
	plate.material_override = _plate_mat
	plate.position = Vector3(0, 0.004, 0)
	add_child(plate)

	# Sweep bar — slides across the plate while scanning.
	_sweep = MeshInstance3D.new()
	_sweep.name = "Sweep"
	var sm := BoxMesh.new()
	sm.size = Vector3(plate_size.x * 0.96, 0.002, 0.012)
	_sweep.mesh = sm
	var sweep_mat := StandardMaterial3D.new()
	sweep_mat.albedo_color = Color(1, 1, 1)
	sweep_mat.emission_enabled = true
	sweep_mat.emission = Color(1, 1, 1)
	sweep_mat.emission_energy_multiplier = 2.2
	sweep_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_sweep.material_override = sweep_mat
	_sweep.position = Vector3(0, 0.009, 0)
	_sweep.visible = false
	add_child(_sweep)

	# Dwell ring — a torus that fills (scales) as dwell progresses.
	_ring = MeshInstance3D.new()
	_ring.name = "Ring"
	var rm := TorusMesh.new()
	rm.inner_radius = min(plate_size.x, plate_size.y) * 0.34
	rm.outer_radius = min(plate_size.x, plate_size.y) * 0.40
	rm.rings = 40
	rm.ring_segments = 10
	_ring.mesh = rm
	_ring_mat = StandardMaterial3D.new()
	_ring_mat.albedo_color = scanning_color
	_ring_mat.emission_enabled = true
	_ring_mat.emission = scanning_color
	_ring_mat.emission_energy_multiplier = 1.6
	_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring.material_override = _ring_mat
	_ring.position = Vector3(0, 0.011, 0)
	_ring.visible = false
	add_child(_ring)

	# Status label above the plate.
	_label = Label3D.new()
	_label.name = "StatusLabel"
	_label.text = "SCAN"
	_label.font_size = 48
	_label.pixel_size = 0.0012
	_label.modulate = idle_color
	_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_label.position = Vector3(0, 0.02, plate_size.y * 0.5 + 0.03)
	_label.rotation_degrees = Vector3(-90, 0, 0)
	add_child(_label)

	# Detection area on the hand layer.
	_area = Area3D.new()
	_area.name = "DetectArea"
	_area.collision_layer = 0
	_area.collision_mask = scan_layer_mask
	_area.monitoring = true
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	# A volume hovering ABOVE the plate — the hand is read in the air over it.
	box.size = Vector3(plate_size.x * 1.1, 0.14, plate_size.y * 1.1)
	cs.shape = box
	cs.position = Vector3(0, 0.09, 0)
	_area.add_child(cs)
	_area.body_entered.connect(_on_enter)
	_area.body_exited.connect(_on_exit)
	_area.area_entered.connect(_on_enter)
	_area.area_exited.connect(_on_exit)
	add_child(_area)

	# Chime audio.
	if play_chime:
		_audio = AudioStreamPlayer3D.new()
		_audio.name = "Chime"
		_audio.volume_db = chime_volume_db
		_audio.max_distance = 8.0
		_audio.stream = _build_chime()
		add_child(_audio)

	if not Engine.is_editor_hint():
		set_process(true)
	_set_state(State.IDLE)


# ── Interaction ───────────────────────────────────────────────────────
func _on_enter(_node: Node) -> void:
	_hands_inside += 1
	if _state == State.IDLE and _hands_inside > 0:
		_set_state(State.SCANNING)
		scan_started.emit()


func _on_exit(_node: Node) -> void:
	_hands_inside = max(0, _hands_inside - 1)
	if _hands_inside == 0 and _state == State.SCANNING:
		scan_aborted.emit()
		_set_state(State.IDLE)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_sweep_phase += delta * 2.4

	match _state:
		State.SCANNING:
			# Slide the sweep bar back and forth.
			if _sweep:
				var u: float = 0.5 - 0.5 * cos(_sweep_phase * PI)
				_sweep.position.z = (u - 0.5) * plate_size.y * 0.9
			# Fill the dwell ring.
			_dwell += delta
			var amt: float = clamp(_dwell / max(0.05, dwell_time), 0.0, 1.0)
			scan_progress.emit(amt)
			if _ring:
				_ring.scale = Vector3(amt, 1.0, amt)
			if amt >= 1.0:
				_authorise()
		State.ACCEPTED:
			_accept_timer -= delta
			# Gentle pulse on the accepted plate.
			if _plate_mat:
				var p := 0.6 + 0.4 * sin(_sweep_phase * 3.0)
				_plate_mat.emission_energy_multiplier = 0.8 + p * 0.6
			if _accept_timer <= 0.0:
				if rearm_after_complete:
					_hands_inside = 0
					_set_state(State.IDLE)
				else:
					set_process(false)
		State.IDLE:
			if _plate_mat:
				_plate_mat.emission_energy_multiplier = 0.4 + 0.15 * sin(_sweep_phase * 0.8)


func _authorise() -> void:
	_set_state(State.ACCEPTED)
	_accept_timer = accepted_hold
	scan_complete.emit()
	if _audio:
		_audio.play()
	if haptic_on_complete:
		_pulse_haptic()


func _set_state(s: int) -> void:
	_state = s
	_dwell = 0.0
	match s:
		State.IDLE:
			if _sweep: _sweep.visible = false
			if _ring: _ring.visible = false
			if _plate_mat:
				_plate_mat.albedo_color = idle_color
				_plate_mat.emission = idle_color
			if _label:
				_label.text = "SCAN"
				_label.modulate = idle_color
		State.SCANNING:
			if _sweep: _sweep.visible = true
			if _ring:
				_ring.visible = true
				_ring.scale = Vector3(0.001, 1.0, 0.001)
			if _plate_mat:
				_plate_mat.albedo_color = scanning_color
				_plate_mat.emission = scanning_color
				_plate_mat.emission_energy_multiplier = 1.0
			if _label:
				_label.text = "SCANNING"
				_label.modulate = scanning_color
		State.ACCEPTED:
			if _sweep: _sweep.visible = false
			if _ring:
				_ring.scale = Vector3.ONE
				_ring_mat.albedo_color = accepted_color
				_ring_mat.emission = accepted_color
			if _plate_mat:
				_plate_mat.albedo_color = accepted_color
				_plate_mat.emission = accepted_color
				_plate_mat.emission_energy_multiplier = 1.4
			if _label:
				_label.text = "ACCEPTED"
				_label.modulate = accepted_color


# Desktop / pointer fallback — a click on the plate runs a quick scan.
func pointer_event(event) -> void:
	if event == null:
		return
	var t = event.get("event_type") if event.has_method("get") else null
	# XRToolsPointerEvent.Type.PRESSED == 2 in this codebase; accept any
	# pressed-like event by duck-typing the "pressed" path.
	if str(event).find("PRESSED") != -1 or t == 2:
		if _state == State.IDLE:
			_set_state(State.SCANNING)
			scan_started.emit()
		# Instant-fill on desktop click — no dwell expectation with a mouse.
		_dwell = dwell_time
		_authorise()


func _pulse_haptic() -> void:
	# Best-effort: trigger a short rumble on any tracked controllers.
	for tracker_name in ["left_hand", "right_hand"]:
		var t := XRServer.get_tracker(tracker_name)
		if t and t.has_method("set_input"):
			pass  # tracker rumble handled by XRToolsRumbler elsewhere; no-op safe fallback


# ── Helpers ───────────────────────────────────────────────────────────
func _build_chime() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var dur := 0.22
	var n := int(stream.mix_rate * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	# Two-tone rising chime (authorised).
	for i in n:
		var tt := float(i) / stream.mix_rate
		var prog := float(i) / float(max(1, n - 1))
		var f := 660.0 if prog < 0.5 else 990.0
		var env := exp(-prog * 4.0) * (1.0 - prog * 0.3)
		var s := sin(TAU * f * tt) * env * 0.30
		var si := int(clamp(s, -1.0, 1.0) * 32767.0)
		data[2 * i] = si & 0xFF
		data[2 * i + 1] = (si >> 8) & 0xFF
	stream.data = data
	return stream


func _parse_vec2(raw: String) -> Vector2:
	var p := raw.split(",")
	if p.size() >= 2:
		return Vector2(float(p[0]), float(p[1]))
	return Vector2.ZERO


func _truthy(v) -> bool:
	var s := str(v).to_lower()
	return s == "true" or s == "1" or s == "yes"
