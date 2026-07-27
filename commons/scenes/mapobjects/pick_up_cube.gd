# pick_up_cube.gd - Updated to work with GameManager singleton
extends Node3D

class_name PickupCube

const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: the project's generic manipulable — a half-metre cube that exists to be taken and has no
#   other argument. A black body drawn in orange wireframe with a cyan glow along the edges, turning
#   on its own axis and bobbing, until a body walks into its detection volume and it is gone with a
#   rising square-wave chirp. It is the prefab condition in its purest form: not a thing that means
#   something, a thing that is available.
# desire: to be picked up. That is the whole of it.
# critical_parameter: stock — what the cube is MADE OF (wire | foam | crate | steel | clay); and
#   custody — the mark the world's accounting has left on it (none | tally | seal | wear). The eight
#   original exports are score (points_value) and tempo (rotation_speed, bob_speed, bob_height,
#   freq_start, freq_end, decay_rate, sound_duration); none of them changes what the object IS, and
#   none of them is visible in a still frame.
# triggers: _ready builds the body from stock and the dressing from custody; DetectionArea
#   body_entered → collect() → GameManager.add_points; apply_grid_config({stock, custody, stock_no}).
# emerges: a row of these stops reading as one prefab repeated and starts reading as a consignment —
#   crates on a dock, foam blocks in a prop store, billets on a bench, numbered stock, sealed goods.
#   The cube does not change what it does. It changes what economy it was made for.
# needs: BakedTextAlbedo for the stock number; GameManager for the score; the Grid shader in
#   pick_up_cube.tscn for the legacy wire body.
# relationships: subclassed by commons/primitives/cubes/pickups/pickup_wrapper.gd (inherits the
#   family); scattered by PickupCubePlacer; its sound is driven map-wide by MarioSoundController.
# truth: an object whose only identity is "graspable" has no identity of its own. It borrows one
#   from the material it was cast in and from whoever has counted it.

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-07-27). 154 placements across 53 maps — the most
# placed loose object in the world — and exactly one look: a black cube in an
# orange wireframe with a cyan edge glow. All eight existing exports are a score
# and a set of RATES. Not one of them can be seen in a still frame, which is the
# same as saying the artifact had no DNA at all: 154 identical tiles.
#
# The identity that was already there, unwritten, is the prefab condition. This
# is the thing the project reaches for whenever it needs "an object" — it is the
# placeholder that never got replaced. So the two axes are the two questions you
# can ask a placeholder that it cannot answer about itself:
#
#   stock     WHAT IT IS MADE OF    wire · foam · crate · steel · clay
#   custody   WHO HAS COUNTED IT    none · tally · seal · wear
#
# `stock` is material and construction: the digital primitive (legacy), the grey-
# box foam block the prop store cuts with a hot wire, a battened shipping crate,
# a machined steel billet with broken edges, and a hand-pressed clay lump that is
# not square — four industrial economies and one refusal of them.
#
# `custody` is the record: nothing, a stencilled stock number on all four faces
# and a docket on the lid, factory shrink-film with corner protectors and a
# strap, or the grease band and rubbed corners of something that has been in
# hands. Counted, sealed, handled — or unaccounted for, which is the default and
# the honest description of what this object has been for 154 placements.
#
# stock=wire, custody=none is the legacy lineage. It returns from _build_dna()
# before touching a material, a transform or a child node, so every existing
# placement renders the exact same pixels it did yesterday.
#
# STRICTLY APPEARANCE. This artifact is collected by walking into it, so nothing
# here goes near DetectionArea, its CollisionShape3D, collect(), the GameManager
# call, the generated audio, or any of the rates. The dressing is MeshInstance3D
# children under a single "DnaDressing" holder — meshes do not collide — plus a
# material swap and (for clay only) a rotation on the display mesh, which is a
# sibling of the detection volume and cannot move it.
#
# Deliberately NOT routed through the axes: the bob and the spin. A cube that
# stopped turning would be a different object, and a rate is invisible to the
# still anyway. The spin does mean the yaw at capture time is arbitrary, so every
# variant below is built four-fold symmetric — it reads the same from any angle.
# ─────────────────────────────────────────────────────────────────────────────

@export var points_value: int = 1
@export var rotation_speed: float = 2.0
@export var bob_height: float = 0.2
@export var bob_speed: float = 2.0

# Mario-style sound parameters
@export var freq_start: float = 440.0  ## Start frequency (200-800 Hz)
@export var freq_end: float = 880.0    ## End frequency (400-1200 Hz)
@export var decay_rate: float = 8.0    ## Decay rate (2.0-12.0)
@export var sound_duration: float = 0.5  ## Sound duration in seconds

## AXIS 1 — what the cube is made of. Drives the body material and the
## construction hung on it.
##   wire  (legacy default) the Grid-shader primitive: black faces, orange edges, cyan glow
##   foam  a hot-wire-cut polystyrene block, matte off-white, one cut seam
##   crate a pale ply box inside a full cage of dark timber battens
##   steel a brushed billet with bright machined chamfers on the top and bottom edges
##   clay  a hand-pressed lump: warm terracotta, set slightly off-square, corners thumbed round
@export var stock: String = "wire"

## AXIS 2 — the record the world keeps of it. Purely additive dressing, tinted
## from the stock palette so it crosses with every body.
##   none  (legacy default) unaccounted for
##   tally stencilled stock number on all four faces plus a docket on the lid
##   seal  shrink-film, four orange corner protectors, a strap and a buckle
##   wear  a grease band at grip height and eight rubbed-pale corner caps
@export var custody: String = "none"

## The number printed by custody=tally. Empty derives a stable one from the
## cube's own position, so a scatter of them reads as a numbered consignment
## rather than the same box photographed nine times.
@export var stock_no: String = ""

var original_y: float
var time_passed: float = 0.0
var has_been_collected: bool = false

# Reference to the pickup sound
var pickup_sound: AudioStreamPlayer3D

# Static variables for shared pickup stream management
static var shared_pickup_stream: AudioStream = null
static var default_pickup_stream: AudioStream = null

# Static variables for shared Mario sound parameters
static var shared_freq_start: float = 440.0
static var shared_freq_end: float = 880.0
static var shared_decay_rate: float = 8.0
static var shared_sound_duration: float = 0.5
static var use_shared_parameters: bool = false

func _ready() -> void:
	# Store original position for bobbing motion
	original_y = global_position.y

	# Create and configure the pickup sound
	setup_pickup_sound()

	print("PickupCube: Ready with %d point value" % points_value)

	# DNA. Appended after everything above so the collection path is set up first
	# and is not affected by what the body turns out to be made of. Reads the
	# config_* metadata the grid sets BEFORE add_child(), then builds. Returns
	# immediately on the legacy lineage (wire / none) — see _build_dna().
	_read_meta_overrides()
	_build_dna()

func _process(delta: float) -> void:
	if has_been_collected:
		return
	
	# Rotate the cube
	rotate_y(rotation_speed * delta)
	
	# Make the cube bob up and down
	time_passed += delta
	var bob_offset = sin(time_passed * bob_speed) * bob_height
	global_position.y = original_y + bob_offset

func _is_player(body: Node3D) -> bool:
	# More flexible player detection
	return body.is_in_group("player") or body.is_in_group("vr_player") or body.name.contains("Player") or body.is_in_group("player_body")

func setup_pickup_sound() -> void:
	# Create an AudioStreamPlayer3D node for the pickup sound
	pickup_sound = AudioStreamPlayer3D.new()
	add_child(pickup_sound)

	# Configure the audio properties
	pickup_sound.unit_size = 2.0
	pickup_sound.max_distance = 20.0
	pickup_sound.volume_db = -6.0  # Moderate volume

	# Generate Mario-style pickup sound
	pickup_sound.stream = _generate_mario_pickup_sound()

func _generate_mario_pickup_sound() -> AudioStreamWAV:
	"""Generate Mario-style pickup sound with frequency sweep and exponential decay"""
	const SAMPLE_RATE = 44100

	# Use shared parameters if available (from MarioSoundController)
	var start_freq = shared_freq_start if use_shared_parameters else freq_start
	var end_freq = shared_freq_end if use_shared_parameters else freq_end
	var decay = shared_decay_rate if use_shared_parameters else decay_rate
	var duration = shared_sound_duration if use_shared_parameters else sound_duration

	# Debug output
	var source = "SHARED" if use_shared_parameters else "LOCAL"
	print("PickupCube: Generating %s sound - start:%.1f Hz, end:%.1f Hz, decay:%.2f" % [source, start_freq, end_freq, decay])

	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedByteArray()

	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count

		# Rising frequency from start to end (classic Mario pickup sweep)
		var freq = start_freq + ((end_freq - start_freq) * progress)

		# Exponential decay envelope
		var envelope = exp(-progress * decay)

		# Square wave for retro Mario feel
		var wave = 1.0 if sin(2.0 * PI * freq * t) > 0 else -1.0

		# Apply envelope and convert to 16-bit audio
		var sample_value = wave * envelope * 0.3
		var sample_int = int(sample_value * 32767.0)

		# Append as 16-bit PCM (little endian)
		data.append(sample_int & 0xFF)
		data.append((sample_int >> 8) & 0xFF)

	# Create AudioStreamWAV
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data

	return stream

func collect() -> void:
	if has_been_collected:
		return

	has_been_collected = true

	print("PickupCube: Collected! Adding %d points" % points_value)

	# Send signal to GameManager singleton with pickup position
	GameManager.add_points(points_value, global_position)

	# Regenerate sound with latest parameters (from MarioSoundController if available)
	var fresh_sound = _generate_mario_pickup_sound()

	# Play pickup sound before removing the cube
	var sound_clone = AudioStreamPlayer3D.new()
	get_tree().root.add_child(sound_clone)
	sound_clone.stream = fresh_sound
	sound_clone.global_position = global_position
	sound_clone.volume_db = pickup_sound.volume_db
	sound_clone.pitch_scale = 1.0
	sound_clone.play()

	# Free the cloned sound after it finishes playing
	sound_clone.finished.connect(func(): sound_clone.queue_free())

	# Visual feedback effect
	_play_collection_effect()

	# Remove the pickup from the scene after a brief delay
	await get_tree().create_timer(0.1).timeout
	queue_free()

func _play_collection_effect():
	"""Simple collection effect - scale up only"""
	var mesh_instance = find_child("CubeBaseMesh", true, false)
	if mesh_instance:
		var tween = create_tween()
		tween.tween_property(mesh_instance, "scale", mesh_instance.scale * 1.5, 0.2)

func _on_detection_area_body_entered(body: Node3D) -> void:
	if _is_player(body):
		print("PickupCube: Player detected, collecting item")
		collect()

# Public API for testing
func set_points_value(new_value: int) -> void:
	points_value = new_value
	print("PickupCube: Points value set to %d" % points_value)

# Static functions for shared pickup stream management
static func get_shared_pickup_stream() -> AudioStream:
	return shared_pickup_stream

static func get_default_pickup_stream() -> AudioStream:
	if default_pickup_stream == null:
		_create_default_pickup_stream()
	return default_pickup_stream

static func set_shared_pickup_stream(stream: AudioStream) -> void:
	shared_pickup_stream = stream

static func reset_shared_pickup_stream() -> AudioStream:
	shared_pickup_stream = get_default_pickup_stream()
	return shared_pickup_stream

static func set_shared_mario_parameters(start_freq: float, end_freq: float, decay: float, duration: float) -> void:
	"""Called by MarioSoundController to update shared sound parameters"""
	shared_freq_start = start_freq
	shared_freq_end = end_freq
	shared_decay_rate = decay
	shared_sound_duration = duration
	use_shared_parameters = true
	#print("PickupCube: Shared Mario sound updated - start:%.1f Hz, end:%.1f Hz, decay:%.2f" % [start_freq, end_freq, decay])

static func get_shared_mario_parameters() -> Dictionary:
	"""Get the current shared Mario sound parameters"""
	return {
		"freq_start": shared_freq_start,
		"freq_end": shared_freq_end,
		"decay_rate": shared_decay_rate,
		"duration": shared_sound_duration,
		"enabled": use_shared_parameters
	}

static func disable_shared_parameters() -> void:
	"""Disable shared parameters, use individual cube settings instead"""
	use_shared_parameters = false
	print("PickupCube: Shared parameters disabled, using individual cube settings")

static func _create_default_pickup_stream() -> void:
	# Create a simple default pickup sound
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 44100
	
	# Generate a simple Mario-style pickup sound
	var sample_rate = 44100
	var duration = 0.2
	var samples = int(duration * sample_rate)
	var data = PackedByteArray()
	data.resize(samples * 2)
	
	for i in range(samples):
		var t = float(i) / sample_rate
		var freq1 = 880.0
		var freq2 = 1318.5
		var normalized = clamp(t / duration, 0.0, 1.0)
		var sweep_freq = lerp(freq1, freq2, pow(normalized, 0.7))
		var envelope = 1.0 - normalized  # Simple decay
		var sample = sin(TAU * sweep_freq * t) * envelope * 0.5
		var sample_int = int(clamp(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample_int)

	stream.data = data
	default_pickup_stream = stream


# ═════════════════════════════════════════════════════════════════════════════
# DNA — stock × custody
#
# Everything below is appearance. Nothing here reads or writes the detection
# volume, the collection path, the score, the sound, or any of the rates.
# ═════════════════════════════════════════════════════════════════════════════

# The display cube's geometry, read off pick_up_cube.tscn: a unit BoxMesh at
# scale 0.5 sitting at local y = 0.5, so a 0.5 m cube centred at CORE spanning
# y 0.25..0.75. Hand-kept in step with the scene — the alternative is measuring
# the AABB at runtime, which the transparent seal film would inflate.
const HALF := 0.25
const CORE := Vector3(0.0, 0.5, 0.0)

# Palettes keyed by stock. `body` is the cube's own material — deliberately
# ABSENT from "wire", which is how the legacy lineage keeps the Grid shader that
# is set in the scene file. The other slots dress the custody axis, and they are
# per-stock because a grease band the colour of the body is not a grease band.
# Entries are {c: albedo, r: roughness, m: metallic, e: emission energy};
# missing keys fall back to (0.7 grey, 0.7 rough, no metal, no emission).
const STOCKS := {
	# THE LEGACY LINEAGE. No `body` key: _stock_body() leaves the scene's
	# ShaderMaterial exactly as authored. The dressing colours are picked to
	# read against black-with-orange-edges, not against a diffuse surface.
	"wire": {
		"trim": {"c": Color(0.94, 0.69, 0.00), "r": 0.5, "e": 0.5},
		"cap": {"c": Color(0.96, 0.80, 0.28), "r": 0.4, "e": 0.4},
		"grease": {"c": Color(0.30, 0.26, 0.22), "r": 0.32},
		"label_bg": Color(0.90, 0.88, 0.82),
		"label_fg": Color(0.08, 0.08, 0.10),
		"film": Color(0.55, 0.95, 1.00, 0.13),
	},
	# The prop store's grey-box. Matte, dumb, dead white — the block that stands
	# in for an object nobody has designed yet, which is what this artifact has
	# actually been. Its one mark is the hot-wire seam where it was cut from a
	# bigger block: foam is never made, only divided.
	"foam": {
		"body": {"c": Color(0.88, 0.87, 0.83), "r": 1.0},
		"trim": {"c": Color(0.66, 0.65, 0.62), "r": 1.0},
		"cap": {"c": Color(0.52, 0.51, 0.48), "r": 1.0},
		"grease": {"c": Color(0.36, 0.35, 0.32), "r": 0.5},
		"label_bg": Color(0.97, 0.96, 0.93),
		"label_fg": Color(0.10, 0.10, 0.12),
		"film": Color(0.85, 0.92, 1.00, 0.14),
	},
	# Freight. Pale ply inside a full cage of dark battens — the object as goods
	# in transit, valuable enough to protect and anonymous enough to stack.
	"crate": {
		"body": {"c": Color(0.78, 0.61, 0.35), "r": 0.95},
		"trim": {"c": Color(0.40, 0.28, 0.16), "r": 0.9},
		"cap": {"c": Color(0.93, 0.87, 0.73), "r": 0.85},
		"grease": {"c": Color(0.24, 0.16, 0.09), "r": 0.5},
		"label_bg": Color(0.94, 0.90, 0.78),
		"label_fg": Color(0.16, 0.12, 0.08),
		"film": Color(0.90, 0.88, 0.80, 0.14),
	},
	# The billet. Metallic 0.9 means almost no diffuse return, so it reads far
	# darker and far shinier than its albedo number suggests, and the bright
	# chamfer lands on the top and bottom edges catch every light in the room.
	"steel": {
		"body": {"c": Color(0.62, 0.64, 0.67), "r": 0.28, "m": 0.9},
		"trim": {"c": Color(0.86, 0.88, 0.90), "r": 0.14, "m": 0.95},
		"cap": {"c": Color(0.94, 0.95, 0.97), "r": 0.12, "m": 0.85},
		"grease": {"c": Color(0.10, 0.11, 0.12), "r": 0.35},
		"label_bg": Color(0.12, 0.13, 0.15),
		"label_fg": Color(0.55, 0.90, 0.98),
		"film": Color(0.85, 0.92, 1.00, 0.10),
	},
	# The refusal. Hand-pressed, warm, and NOT SQUARE — the only member of the
	# family whose faces do not line up with the grid it is standing on. A
	# manipulable that was made by being manipulated.
	"clay": {
		"body": {"c": Color(0.66, 0.35, 0.23), "r": 0.95},
		"trim": {"c": Color(0.46, 0.22, 0.14), "r": 0.95},
		"cap": {"c": Color(0.82, 0.57, 0.42), "r": 0.95},
		"grease": {"c": Color(0.30, 0.15, 0.10), "r": 0.55},
		"label_bg": Color(0.92, 0.86, 0.74),
		"label_fg": Color(0.20, 0.10, 0.06),
		"film": Color(0.92, 0.90, 0.84, 0.14),
	},
}

# Packaging is packaging in any material: the corner protector is safety orange
# whatever is inside it. Not routed through the palette on purpose.
const PACK_ORANGE := Color(0.93, 0.44, 0.06)
const PACK_STRAP := Color(0.17, 0.18, 0.21)
const PACK_BUCKLE := Color(0.80, 0.82, 0.85)

# What the scene authored, kept so a late apply_grid_config can put it back.
var _base_mat: Material = null
var _base_rot: Vector3 = Vector3.ZERO
var _base_captured: bool = false
var _built_stock: String = ""
var _built_custody: String = ""


## Read the config_* metadata the grid writes onto the instance before it is
## added to the tree. Same contract as every other promoted artifact.
func _read_meta_overrides() -> void:
	if has_meta("config_stock"):
		stock = str(get_meta("config_stock"))
	if has_meta("config_custody"):
		custody = str(get_meta("config_custody"))
	if has_meta("config_stock_no"):
		stock_no = str(get_meta("config_stock_no"))


## Grid config arrives deferred, i.e. after _ready has already built. Only
## rebuild when a value actually changed; unknown keys (six placements carry
## #layout:row#with_wall:false#with_pillars:false#with_barrier:false, which this
## artifact has never read) are ignored, exactly as they were when this class had
## no configuration method at all.
func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	var was_stock: String = stock
	var was_custody: String = custody
	var was_no: String = stock_no
	_read_meta_overrides()
	if stock != was_stock or custody != was_custody or stock_no != was_no:
		_build_dna()


## The display mesh authored in pick_up_cube.tscn. Null-safe: pickup_wrapper.gd
## subclasses this script onto scenes that have no such child, and they must
## keep working.
func _base_mesh() -> MeshInstance3D:
	var n: Node = find_child("CubeBaseMesh", true, false)
	if n is MeshInstance3D:
		return n as MeshInstance3D
	return null


func _palette() -> Dictionary:
	var p: Variant = STOCKS.get(stock, STOCKS["wire"])
	return p as Dictionary


func _pmat(slot: String) -> StandardMaterial3D:
	var e: Variant = _palette().get(slot, {})
	var d: Dictionary = {}
	if e is Dictionary:
		d = e as Dictionary
	var c: Color = d.get("c", Color(0.7, 0.7, 0.7))
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = float(d.get("r", 0.7))
	var met: float = float(d.get("m", 0.0))
	if met > 0.0:
		m.metallic = met
	var em: float = float(d.get("e", 0.0))
	if em > 0.0:
		m.emission_enabled = true
		m.emission = Color(c.r, c.g, c.b)
		m.emission_energy_multiplier = em
	if c.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


func _pcolor(slot: String, fallback: Color) -> Color:
	var v: Variant = _palette().get(slot, fallback)
	if v is Color:
		return v as Color
	return fallback


func _flat(c: Color, rough: float = 0.7, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if metal > 0.0:
		m.metallic = metal
	if c.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


## All dressing hangs off a single holder so a rebuild is one free() away, and
## so find_child("CubeBaseMesh") in _play_collection_effect never sees it.
func _dressing_root() -> Node3D:
	var old: Node = get_node_or_null("DnaDressing")
	if old != null:
		remove_child(old)
		old.queue_free()
	var holder := Node3D.new()
	holder.name = "DnaDressing"
	add_child(holder)
	return holder


func _box(holder: Node3D, size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	holder.add_child(mi)
	return mi


func _ball(holder: Node3D, radius: float, pos: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = 14
	sm.rings = 7
	mi.mesh = sm
	mi.material_override = mat
	mi.position = pos
	holder.add_child(mi)
	return mi


func _disc(holder: Node3D, radius: float, height: float, pos: Vector3, mat: StandardMaterial3D) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	cm.radial_segments = 10
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	holder.add_child(mi)


# ── the build ────────────────────────────────────────────────────────────────

## THE DEFAULT PATH. stock="wire" and custody="none" reach the early return
## having done one Dictionary.has and two string compares. No node is touched,
## no material is created, no transform is written, not even a find_child. All
## 154 existing placements land here and render exactly what they rendered
## yesterday. An unrecognised stock value degrades to "wire" rather than to an
## arbitrary palette, so a typo in a map token is inert, not disfiguring.
func _build_dna() -> void:
	var s: String = stock if STOCKS.has(stock) else "wire"
	if s == "wire" and custody == "none":
		# Legacy lineage. Only if a previous config had already built something
		# does anything at all happen here.
		if _built_stock != "" or _built_custody != "":
			_restore_base()
			_built_stock = "wire"
			_built_custody = "none"
		return
	_capture_base()
	_built_stock = s
	_built_custody = custody
	var holder: Node3D = _dressing_root()
	_stock_body(holder, s)
	_build_custody(holder)


## Remember what pick_up_cube.tscn authored, once, before the first variant
## build overwrites it — so a late apply_grid_config can put the legacy body
## back exactly as it was rather than guessing at it.
func _capture_base() -> void:
	if _base_captured:
		return
	var mesh: MeshInstance3D = _base_mesh()
	if mesh != null:
		_base_mat = mesh.material_override
		_base_rot = mesh.rotation_degrees
	_base_captured = true


func _restore_base() -> void:
	var old: Node = get_node_or_null("DnaDressing")
	if old != null:
		remove_child(old)
		old.queue_free()
	var mesh: MeshInstance3D = _base_mesh()
	if mesh != null:
		mesh.material_override = _base_mat
		mesh.rotation_degrees = _base_rot


func _stock_body(holder: Node3D, s: String) -> void:
	var mesh: MeshInstance3D = _base_mesh()
	if s == "wire":
		# custody dressing on the legacy body — put the shader back in case a
		# previous config swapped it, and leave the geometry alone.
		if mesh != null:
			mesh.material_override = _base_mat
			mesh.rotation_degrees = _base_rot
		return
	if mesh != null:
		mesh.material_override = _pmat("body")
		mesh.rotation_degrees = _base_rot
	match s:
		"foam":
			_stock_foam(holder)
		"crate":
			_stock_crate(holder)
		"steel":
			_stock_steel(holder)
		"clay":
			_stock_clay(holder, mesh)


## FOAM. A dull off-white block and one seam. Deliberately almost featureless:
## the grey-box is supposed to look like a decision nobody has made. The seam
## rides above centre so it never collides with custody=wear's grease band.
func _stock_foam(holder: Node3D) -> void:
	_box(holder, Vector3(0.508, 0.013, 0.508), CORE + Vector3(0, 0.062, 0), _pmat("trim"))


## CRATE. Twelve battens — four corner posts standing 2.6 cm proud of the lid and
## base, and eight rails closing the top and bottom frames. A full cage, so the
## silhouette reads as freight from any yaw the spin happens to stop at.
func _stock_crate(holder: Node3D) -> void:
	var timber: StandardMaterial3D = _pmat("trim")
	var t: float = 0.052
	var run: float = 0.552
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var x: float = float(sx) * HALF
			var z: float = float(sz) * HALF
			_box(holder, Vector3(t, run, t), CORE + Vector3(x, 0.0, z), timber)
	for sy in [-1.0, 1.0]:
		var y: float = float(sy) * HALF
		for s2 in [-1.0, 1.0]:
			var o: float = float(s2) * HALF
			_box(holder, Vector3(run, t, t), CORE + Vector3(0.0, y, o), timber)
			_box(holder, Vector3(t, t, run), CORE + Vector3(o, y, 0.0), timber)


## STEEL. Chamfer lands on the top and bottom edges ONLY — the vertical corners
## stay sharp, which is what separates a machined billet from the crate's cage at
## a glance — plus four dark socket heads standing proud of the lid.
func _stock_steel(holder: Node3D) -> void:
	var bright: StandardMaterial3D = _pmat("trim")
	var t: float = 0.034
	for sy in [-1.0, 1.0]:
		var y: float = float(sy) * HALF
		for s2 in [-1.0, 1.0]:
			var o: float = float(s2) * HALF
			_box(holder, Vector3(0.5, t, t), CORE + Vector3(0.0, y, o), bright)
			_box(holder, Vector3(t, t, 0.5), CORE + Vector3(o, y, 0.0), bright)
	var head: StandardMaterial3D = _pmat("grease")
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var x: float = float(sx) * 0.125
			var z: float = float(sz) * 0.125
			_disc(holder, 0.028, 0.012, CORE + Vector3(x, HALF + 0.006, z), head)


## CLAY. The body itself is set a few degrees off true — the only member of the
## family that does not agree with the grid — and eight thumbed lumps round the
## corners off. The rotation is written to the DISPLAY MESH, which is a sibling
## of DetectionArea: the volume you walk into does not move by a millimetre.
func _stock_clay(holder: Node3D, mesh: MeshInstance3D) -> void:
	if mesh != null:
		mesh.rotation_degrees = _base_rot + Vector3(2.5, 0.0, -3.5)
	var body: StandardMaterial3D = _pmat("body")
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var p: Vector3 = Vector3(float(sx) * 0.20, float(sy) * 0.20, float(sz) * 0.20)
				_ball(holder, 0.085, CORE + p, body)
	var groove := _box(holder, Vector3(0.522, 0.018, 0.522), CORE + Vector3(0, -0.085, 0), _pmat("trim"))
	groove.rotation_degrees = Vector3(2.5, 0.0, -3.5)


# ── custody ──────────────────────────────────────────────────────────────────

func _build_custody(holder: Node3D) -> void:
	match custody:
		"tally":
			_custody_tally(holder)
		"seal":
			_custody_seal(holder)
		"wear":
			_custody_wear(holder)
		_:
			pass


## The stock number. Derived from the cube's own position when unset, so a
## scatter of them in one map are all different and all stable across captures —
## a consignment, not one box photographed nine times.
func _tally_text() -> String:
	if stock_no != "":
		return stock_no
	var p: Vector3 = global_position
	var a: int = int(round(absf(p.x) * 100.0))
	var b: int = int(round(absf(p.y) * 100.0))
	var c: int = int(round(absf(p.z) * 100.0))
	var h: int = ((a * 73856093) ^ (b * 19349663) ^ (c * 83492791)) & 0x7FFFFFFF
	return "PU-%04d" % (h % 9000 + 1000)


## TALLY. A printed number on all four side faces plus a docket lying on the
## lid. Four faces rather than one because the cube is turning: a single label
## would be a coin-flip on whether the variant is legible at all.
func _custody_tally(holder: Node3D) -> void:
	var txt: String = _tally_text()
	var bg: Color = _pcolor("label_bg", Color(0.90, 0.88, 0.82))
	var fg: Color = _pcolor("label_fg", Color(0.09, 0.09, 0.11))
	var out: float = HALF + 0.007
	var offs: Array = [
		Vector3(0.0, 0.0, out), Vector3(out, 0.0, 0.0),
		Vector3(0.0, 0.0, -out), Vector3(-out, 0.0, 0.0),
	]
	var yaws: Array = [0.0, 90.0, 180.0, 270.0]
	for i in 4:
		var plate: MeshInstance3D = BakedText.make_panel_mesh(txt, bg, fg, Vector2(0.30, 0.125), 1400, false)
		if plate != null:
			plate.position = CORE + (offs[i] as Vector3)
			plate.rotation_degrees = Vector3(0.0, float(yaws[i]), 0.0)
			plate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			holder.add_child(plate)
	# the docket taped to the lid — visible because a 1.65 m eye looks DOWN on a
	# half-metre cube, and it is what makes "counted" read rather than "labelled"
	var docket: MeshInstance3D = BakedText.make_panel_mesh(txt, bg, fg, Vector2(0.17, 0.095), 1400, false)
	if docket != null:
		docket.position = CORE + Vector3(0.0, HALF + 0.006, 0.0)
		docket.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
		docket.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(docket)


## SEAL. Never opened. A film shell 7.5 cm wider than the cube, four safety-
## orange corner protectors running its full height, and a strap with a buckle.
## The silhouette grows by a quarter — this is the variant you can identify from
## the far side of the room, which is the point of an axis.
func _custody_seal(holder: Node3D) -> void:
	var film := _box(holder, Vector3(0.585, 0.585, 0.585), CORE,
			_flat(_pcolor("film", Color(0.85, 0.92, 1.0, 0.13)), 0.05))
	film.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The protectors sit at 0.258, not flush at 0.25, so they ENGULF the crate's
	# corner posts instead of sharing a face with them — coplanar faces 1 mm apart
	# z-fight across a room, and this pair is the one crossing that would do it.
	var prot: StandardMaterial3D = _flat(PACK_ORANGE, 0.6)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var x: float = float(sx) * 0.258
			var z: float = float(sz) * 0.258
			_box(holder, Vector3(0.058, 0.585, 0.058), CORE + Vector3(x, 0.0, z), prot)
	var strap: StandardMaterial3D = _flat(PACK_STRAP, 0.7)
	for s in [-1.0, 1.0]:
		var o: float = float(s) * 0.302
		_box(holder, Vector3(0.62, 0.045, 0.022), CORE + Vector3(0.0, 0.0, o), strap)
		_box(holder, Vector3(0.022, 0.045, 0.62), CORE + Vector3(o, 0.0, 0.0), strap)
	_box(holder, Vector3(0.085, 0.062, 0.030), CORE + Vector3(0.0, 0.0, 0.315),
			_flat(PACK_BUCKLE, 0.3, 0.8))


## WEAR. Been in hands. A dark grease belt at grip height and eight corner caps
## rubbed back to a paler tone — the two places a carried object actually wears.
## Both are tinted from the stock palette, so grease on a black wire cube is a
## warm grey stripe and grease on pale ply is nearly black.
func _custody_wear(holder: Node3D) -> void:
	_box(holder, Vector3(0.518, 0.105, 0.518), CORE, _pmat("grease"))
	var cap: StandardMaterial3D = _pmat("cap")
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var p: Vector3 = Vector3(float(sx) * 0.2225, float(sy) * 0.2225, float(sz) * 0.2225)
				_box(holder, Vector3(0.085, 0.085, 0.085), CORE + p, cap)
