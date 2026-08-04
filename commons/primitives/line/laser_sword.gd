extends XRToolsPickable
class_name LaserSword

# @identity
# essence: a line you hold like a sword — glowing blade extending from a handle, pure directed length
# desire: to feel direction as something your arm produces — the blade points where you point
# critical_parameter: blade_length — how far the line extends from your grip; adjustable by gripping tighter
# triggers: pickup ignites the blade with audio hum; swing speed modulates pitch and glow intensity
# emerges: direction is not abstract — it is where your wrist aims; length is how far your intention reaches
# needs: XRToolsPickable [has]; CylinderMesh blade [has]; hum audio [has]; haptic [has]
# relationships: grabbable_line is passive measurement; laser_sword is active direction; both teach line
# truth: a directed line segment is a decision about where to point

## Grabbable laser sword — a glowing blade on a handle.
## Pick it up, swing it. The blade hums. Speed affects pitch and glow.
## Teaching tool: line as direction, length as extension of will.

@export_group("Blade")
@export var blade_length: float = 0.8
@export var blade_radius: float = 0.008
@export var blade_color: Color = Color(0.3, 0.5, 1.0)  # blue
@export var blade_emission: float = 3.0

@export_group("Handle")
@export var handle_length: float = 0.14
@export var handle_radius: float = 0.016
@export var handle_color: Color = Color(0.25, 0.23, 0.20)  # Rams dark

@export_group("Audio")
@export var hum_volume_db: float = -16.0
@export var hum_base_frequency: float = 120.0
@export var swing_pitch_range: float = 0.6

@export_group("DNA")
## STAGE-2 DNA, hand promotion 2026-08-03.
##
## What the sword looks like when NOBODY IS HOLDING IT — which is what it looks like in
## a map for all but a few seconds, and what it looks like in every still ever taken of
## it. `_ready` ended with `_blade_mesh.visible = false`, hard-coded, so standing on its
## plinth this artifact is a 14 cm handle and a copper disc; the 80 cm line the whole
## piece is about exists only inside a fist. That is a real position — direction is
## produced by a body — but it was an assumption nobody could argue with, and it is the
## reason a capture of this token photographs almost nothing.
##
## So the axis is whether the line pre-exists the hand:
##   dark   the object alone is only a grip; there is no line until someone takes it
##   pilot  a stub burns at the guard — the tool idles, asserting its origin and nothing more
##   ghost  the line is drawn full length but cold: geometry without commitment
##   lit    it burns unattended; the vector is a fact about the world, not about the arm
##
## Picking it up still ignites a full blade under every value — _ignite() sets length,
## emission and alpha explicitly now — so nothing about the held sword changes.
@export_enum("dark", "pilot", "ghost", "lit") var repose: String = "dark"
const REPOSE_KEYS: Array[String] = ["dark", "pilot", "ghost", "lit"]
## Fraction of blade_length the `pilot` stub burns.
const PILOT_FRACTION: float = 0.15
## Alpha the `ghost` blade drops to; `lit`/`dark` keep the shipped 0.85.
const GHOST_ALPHA: float = 0.30

# Internal
var _blade_mesh: MeshInstance3D
var _blade_cylinder: CylinderMesh
var _blade_material: StandardMaterial3D
var _handle_mesh: MeshInstance3D
var _guard_mesh: MeshInstance3D
var _hum_player: AudioStreamPlayer3D
var _hum_stream: AudioStreamWAV
var _is_held := false
var _last_position: Vector3
var _current_speed: float = 0.0
var _blade_visible := false
## True once _ready has built the body. apply_grid_config arrives deferred from
## GridInteractablesComponent, so a restyle before the first build would act on nulls.
var _built := false


func _ready() -> void:
	super()
	_build_handle()
	_build_guard()
	_build_blade()
	_build_collision()
	_setup_hum_audio()

	picked_up.connect(_on_sword_picked_up)
	dropped.connect(_on_sword_dropped)

	# Blade starts as the repose axis says. At repose="dark", the default, this is the
	# shipped `_blade_mesh.visible = false` and nothing else — the mesh already carries
	# blade_length, blade_emission and alpha 0.85 from _build_blade().
	_apply_repose()
	_built = true


func _process(delta: float) -> void:
	if _is_held:
		# Calculate swing speed
		var current_pos := global_position
		_current_speed = current_pos.distance_to(_last_position) / maxf(delta, 0.001)
		_last_position = current_pos

		# Modulate hum pitch by speed
		if _hum_player:
			_hum_player.pitch_scale = 1.0 + clampf(_current_speed * 0.15, 0.0, swing_pitch_range)

		# Modulate blade glow by speed
		if _blade_material:
			var speed_glow := clampf(_current_speed * 0.5, 0.0, 3.0)
			_blade_material.emission_energy_multiplier = blade_emission + speed_glow


# ── Handle ───────────────────────────────────────────────────────────

func _build_handle() -> void:
	_handle_mesh = MeshInstance3D.new()
	_handle_mesh.name = "Handle"
	var cyl := CylinderMesh.new()
	cyl.height = handle_length
	cyl.top_radius = handle_radius
	cyl.bottom_radius = handle_radius * 1.1  # slight taper
	cyl.radial_segments = 12
	_handle_mesh.mesh = cyl

	var mat := StandardMaterial3D.new()
	mat.albedo_color = handle_color
	mat.metallic = 0.7
	mat.roughness = 0.3
	_handle_mesh.material_override = mat
	_handle_mesh.position = Vector3(0, 0, 0)
	add_child(_handle_mesh)


func _build_guard() -> void:
	# Copper disc between handle and blade
	_guard_mesh = MeshInstance3D.new()
	_guard_mesh.name = "Guard"
	var cyl := CylinderMesh.new()
	cyl.height = 0.006
	cyl.top_radius = handle_radius * 1.8
	cyl.bottom_radius = handle_radius * 1.8
	cyl.radial_segments = 16
	_guard_mesh.mesh = cyl

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.75, 0.38, 0.13)  # copper
	mat.metallic = 0.6
	mat.roughness = 0.35
	mat.emission_enabled = true
	mat.emission = Color(0.75, 0.38, 0.13)
	mat.emission_energy_multiplier = 0.3
	_guard_mesh.material_override = mat
	_guard_mesh.position = Vector3(0, handle_length / 2.0, 0)
	add_child(_guard_mesh)


# ── Blade ────────────────────────────────────────────────────────────

func _build_blade() -> void:
	_blade_mesh = MeshInstance3D.new()
	_blade_mesh.name = "Blade"
	_blade_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_blade_cylinder = CylinderMesh.new()
	_blade_cylinder.height = blade_length
	_blade_cylinder.top_radius = blade_radius * 0.3  # tapered tip
	_blade_cylinder.bottom_radius = blade_radius
	_blade_cylinder.radial_segments = 8
	_blade_mesh.mesh = _blade_cylinder

	_blade_material = StandardMaterial3D.new()
	_blade_material.albedo_color = blade_color
	_blade_material.emission_enabled = true
	_blade_material.emission = blade_color
	_blade_material.emission_energy_multiplier = blade_emission
	_blade_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_blade_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_blade_material.albedo_color.a = 0.85
	_blade_mesh.material_override = _blade_material

	# Position blade above guard
	_blade_mesh.position = Vector3(0, handle_length / 2.0 + blade_length / 2.0 + 0.006, 0)
	add_child(_blade_mesh)


func _build_collision() -> void:
	var col := CollisionShape3D.new()
	col.name = "HandleCollision"
	var capsule := CapsuleShape3D.new()
	capsule.radius = handle_radius * 2.5
	capsule.height = handle_length + 0.04
	col.shape = capsule
	add_child(col)


# ── Audio ────────────────────────────────────────────────────────────

func _setup_hum_audio() -> void:
	_hum_stream = _generate_hum()
	_hum_player = AudioStreamPlayer3D.new()
	_hum_player.name = "HumPlayer"
	_hum_player.stream = _hum_stream
	_hum_player.volume_db = -80.0  # silent until ignited
	_hum_player.autoplay = true
	_hum_player.unit_size = 3.0
	_hum_player.max_distance = 8.0
	add_child(_hum_player)


func _generate_hum() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var duration := 0.5
	var sample_count := int(stream.mix_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for i in sample_count:
		var t: float = float(i) / stream.mix_rate
		# Layered sine waves for rich hum
		var s: float = sin(TAU * hum_base_frequency * t) * 0.3
		s += sin(TAU * hum_base_frequency * 2.0 * t) * 0.15  # octave
		s += sin(TAU * hum_base_frequency * 3.0 * t) * 0.08  # fifth
		s += sin(TAU * (hum_base_frequency + 1.5) * t) * 0.1  # slight detune = buzz
		var int_sample: int = int(clampf(s, -1.0, 1.0) * 32767.0)
		data[2 * i] = int_sample & 0xFF
		data[2 * i + 1] = (int_sample >> 8) & 0xFF

	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	return stream


# ── Ignition ─────────────────────────────────────────────────────────

## In hand the sword is a sword under every repose value. The three assignments that were
## not here before (length, emission, alpha) are no-ops at repose="dark", because nothing
## has touched them — they exist so `pilot` and `ghost` come up to full when gripped.
func _ignite() -> void:
	_blade_visible = true
	_style_blade(blade_length, blade_emission, 0.85, false)
	_blade_mesh.visible = true
	if _hum_player:
		_hum_player.volume_db = hum_volume_db


## Dropped, it returns to its repose — which at the default is exactly the old
## hide-and-silence, emission reset included.
func _extinguish() -> void:
	_blade_visible = false
	_apply_repose()


## Blade geometry and material for a given burning length. `shaded` is the one thing only
## `ghost` asks for — every other caller passes false, which puts the shipped UNSHADED
## mode back, so no path can leave the material in a state _build_blade did not.
func _style_blade(length: float, emission: float, alpha: float, shaded: bool) -> void:
	if _blade_cylinder != null and _blade_mesh != null:
		_blade_cylinder.height = length
		_blade_mesh.position = Vector3(0, handle_length / 2.0 + length / 2.0 + 0.006, 0)
	if _blade_material == null:
		return
	if shaded:
		_blade_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	else:
		_blade_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_blade_material.emission_energy_multiplier = emission
	_blade_material.albedo_color = blade_color
	_blade_material.albedo_color.a = alpha


func _apply_repose() -> void:
	if _blade_mesh == null:
		return
	match repose:
		"lit":
			_style_blade(blade_length, blade_emission, 0.85, false)
			_blade_mesh.visible = true
			if _hum_player:
				_hum_player.volume_db = hum_volume_db
		"pilot":
			_style_blade(blade_length * PILOT_FRACTION, blade_emission, 0.85, false)
			_blade_mesh.visible = true
			if _hum_player:
				_hum_player.volume_db = -80.0
		"ghost":
			# Cold: the line is drawn, not burning. Shaded rather than unshaded, so it
			# takes the room's light like any other object instead of emitting its own —
			# the difference between a line that is there and a line that is on.
			_style_blade(blade_length, 0.0, GHOST_ALPHA, true)
			_blade_mesh.visible = true
			if _hum_player:
				_hum_player.volume_db = -80.0
		_:
			# "dark", and anything unrecognised: the shipped behaviour, byte for byte —
			# blade_length, blade_emission, alpha 0.85, unshaded, hidden, silent, which is
			# exactly what _build_blade left behind and what `visible = false` did.
			_style_blade(blade_length, blade_emission, 0.85, false)
			_blade_mesh.visible = false
			if _hum_player:
				_hum_player.volume_db = -80.0


# ── Pickup ───────────────────────────────────────────────────────────

func _on_sword_picked_up(_pickable) -> void:
	_is_held = true
	_last_position = global_position
	_ignite()
	var controller := get_picked_up_by_controller()
	if controller:
		controller.trigger_haptic_pulse("haptic", 60.0, 0.6, 0.15, 0)


func _on_sword_dropped(_pickable) -> void:
	_is_held = false
	_current_speed = 0.0
	_extinguish()
	var controller := get_picked_up_by_controller()
	if controller:
		controller.trigger_haptic_pulse("haptic", 40.0, 0.3, 0.08, 0)


# ── Grid Config ──────────────────────────────────────────────────────

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("blade_length"):
		blade_length = config_data["blade_length"]
	if config_data.has("blade_color"):
		var c = config_data["blade_color"]
		if c is String:
			blade_color = Color.html(c)
		elif c is Color:
			blade_color = c
	if config_data.has("blade_emission"):
		blade_emission = config_data["blade_emission"]
	# The DNA axis. Restyles only when the value both validates and CHANGED, only after
	# _ready has built the body, and never mid-swing — this arrives deferred, and none of
	# the 22 existing placements passes a `repose` key, so all 22 keep a dark blade.
	if config_data.has("repose"):
		var r: String = _pick_axis(String(config_data["repose"]), REPOSE_KEYS, repose)
		if r != repose:
			repose = r
			if _built and not _is_held:
				_apply_repose()


func _pick_axis(raw: String, allowed: Array[String], fallback: String) -> String:
	var v: String = raw.strip_edges().to_lower()
	return v if allowed.has(v) else fallback
