extends XRToolsPickable
class_name GrabbableLine

# @identity
# essence: a line segment you hold as one object — grab anywhere along its length to move it through space
# desire: learner feels the line as a single entity, not two separate points — unity before decomposition
# critical_parameter: grain — how finely the segment admits it is made of parts, from one unbroken rod to the two boundary points alone; the envelope never changes, the mass inside it does
# triggers: grab the body to move; resistance glitch fires when position crosses integer grid lines
# emerges: a line is one thing made of two points — holding it whole precedes understanding it as parts
# needs: XRToolsPickable [has]; CylinderMesh [has]; endpoint spheres [has]; Label3D [has]
# relationships: complement to line.tscn (endpoints-first); precedes line in sequence for whole→parts arc
# truth: you can hold a line before you know it has endpoints

## Whole-line grabbable — pick up anywhere along the cylinder to move the entire line.
## Endpoints are visible but not independently grabbable. Fixed length.
## Includes the integer-resistance glitch from line.gd.

# ── Stage-2 DNA: grain ────────────────────────────────────────────────
#
# WHAT WAS ALREADY HERE AND WAS NOT PROMOTED. This artifact's loudest
# behaviour is the resistance glitch — jitter, a detuning noise loop, haptics,
# a reddening label — and every one of those is a RATE. A still frame cannot
# photograph a frequency; sweeping resistance_threshold would have produced
# identical tiles and a confident verdict about the capture rather than the
# design. The knobs it does expose (line_length, line_thickness,
# endpoint_radius) are sizes, and a size self-cancels under an AABB-fitted
# camera. So none of them is the axis.
#
# WHY NOT `readout`, THE FAMILY WORD. line / line_interface / xyz_slider_plate
# carry readout = none | numeral | gradation | lattice, and rungs 0 and 1 would
# fit this artifact exactly — it prints "%.2fm" over its midpoint. Rung 3 does
# not. There, `lattice` means the privileged whole numbers on the LENGTH scale,
# because line.gd's resistance fires on the distance between its two handles.
# Here resistance fires on global_position — the whole numbers this artifact
# privileges are stations in the ROOM, not readings on the rule. Borrowing the
# ladder would put a hot collar on a scale that is not where the law lives, so
# the word is declined rather than half-taken. See the promotion note in the
# registry.
#
# THE AXIS. `grain` is the project's one word for HOW FINELY A BODY IS MADE OF
# PARTS, taken character for character from commons/primitives/cubes/
# cube_scene.gd and prism_block — the deliberate shared-vocabulary case. The
# same five rungs, read on a 1-D body, and the reading is exact:
#
#   solid      one unbroken rod, two endpoint beads — the shipped look, to the
#              byte. Nothing added, nothing hidden. All 16 rooms.
#   split      parted once at the midpoint: two half-rods with a gap. The
#              object you hold as ONE is drawn as two.
#   quartered  four sub-segments, three gaps.
#   lattice    twelve units on a regular pitch — the segment as a repeated cell,
#              a rule made of ticks rather than of extent.
#   shell      no body at all: the two boundary points and nothing between.
#              For a cube, shell is the twelve edges; for a segment the boundary
#              IS the two endpoints, ∂[a,b] = {a,b}, so the same word lands on
#              the exact same idea one dimension down.
#
# Every rung keeps the ±line_length/2 envelope, so the silhouette's extent is
# constant and only the mass inside it changes — the same discipline cube_scene
# holds. All five are shape/count values, standing still, with no randf in them:
# five variants are five photographs of one object.
#
# Worth varying because the artifact's own truth line is "you can hold a line
# before you know it has endpoints" — and until now it could draw exactly one
# opinion about what a line is made of, in every room, which is that claim's
# contradiction standing in sixteen places. `split` is the sharpest: the thing
# still picks up as one rigid body while its picture says it is two.

@export_group("Line Properties")
@export var line_length: float = 0.24:
	set(value):
		line_length = clamp(value, 0.05, 5.0)
		if is_inside_tree():
			_rebuild()
@export var line_thickness: float = 0.008
@export var line_color: Color = Color(0.788, 0.463, 0.996)  # purple, matching line.gd
@export var endpoint_radius: float = 0.018

@export_group("Display")
@export var show_length_label: bool = true
@export var show_endpoints: bool = true

@export_group("Resistance Glitch")
@export var enable_resistance: bool = true
@export var resistance_threshold: float = 0.08
@export var max_jitter: float = 0.015
@export var haptic_intensity_max: float = 0.8
@export var glitch_sound_volume_db: float = -12.0

@export_group("Grain")
## How finely the segment is made of parts. `solid` is the shipped look exactly
## — zero nodes added, nothing hidden. The four others hide the shipped rod and
## build a differently-divided body inside the same ±line_length/2 envelope.
@export_enum("solid", "split", "quartered", "lattice", "shell") var grain: String = "solid"

## Allow-list for the axis. Anything outside it is a typo in a map token and
## falls back to the value already held, which for a fresh instance is the
## shipped look. A typo must never empty a live room.
const GRAINS: PackedStringArray = ["solid", "split", "quartered", "lattice", "shell"]

## How many pieces each rung draws. `shell` draws none: it is the boundary.
const SPLIT_PARTS: int = 2
const QUARTER_PARTS: int = 4
const LATTICE_PARTS: int = 12

## Fraction of each part's pitch spent on the gap. One number for all three
## divided rungs, so the pieces read as the same family of cuts at three
## coarsenesses rather than three unrelated recipes.
const PART_GAP_FRACTION: float = 0.28

# Internal
var _built: bool = false
var _parts_root: Node3D
var _parts: Array[MeshInstance3D] = []
var _line_mesh: MeshInstance3D
var _cylinder: CylinderMesh
var _line_material: StandardMaterial3D
var _endpoint_a: MeshInstance3D
var _endpoint_b: MeshInstance3D
var _length_label: Label3D
var _glitch_player: AudioStreamPlayer3D
var _glitch_stream: AudioStreamWAV
var _is_held := false
var _current_controller: XRController3D


func _ready() -> void:
	super()
	# The grid writes config_* metadata BEFORE add_child and only calls
	# apply_grid_config deferred, so reading it here lets _ready build the right
	# body first time and leaves the deferred call with nothing to tear down.
	_read_metadata_overrides()
	_build_collision()
	_build_line_mesh()
	_build_endpoints()
	_build_grain()
	if show_length_label:
		_build_label()
	_setup_glitch_audio()
	_rebuild()
	_built = true

	picked_up.connect(_on_line_picked_up)
	dropped.connect(_on_line_dropped)


func _process(_delta: float) -> void:
	if enable_resistance and _is_held:
		_process_position_resistance()


# ── Build ────────────────────────────────────────────────────────────

func _build_collision() -> void:
	# Capsule collision along the line body so you can grab anywhere
	var col := CollisionShape3D.new()
	col.name = "LineCollision"
	var capsule := CapsuleShape3D.new()
	capsule.radius = max(line_thickness * 3.0, 0.025)  # wide enough to grab
	capsule.height = line_length + capsule.radius * 2.0
	col.shape = capsule
	# Capsule aligns along Y by default — line extends along X, so rotate
	col.rotation_degrees.z = 90.0
	add_child(col)


func _build_line_mesh() -> void:
	_line_mesh = MeshInstance3D.new()
	_line_mesh.name = "LineMesh"
	_line_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_line_mesh)

	_cylinder = CylinderMesh.new()
	_cylinder.top_radius = line_thickness
	_cylinder.bottom_radius = line_thickness
	_cylinder.radial_segments = 8
	_cylinder.rings = 0
	_line_mesh.mesh = _cylinder

	_line_material = StandardMaterial3D.new()
	_line_material.albedo_color = line_color
	_line_material.metallic = 0.8
	_line_material.roughness = 0.1
	_line_material.emission_enabled = true
	_line_material.emission = line_color
	_line_material.emission_energy_multiplier = 0.8
	_line_mesh.material_override = _line_material

	# Line extends along X axis — rotate cylinder (default Y) to lie along X
	_line_mesh.rotation_degrees.z = 90.0


func _build_endpoints() -> void:
	# show_endpoints keeps its legacy veto at every rung but `shell`, where the
	# two boundary points ARE the artifact — suppressing them there would render
	# nothing at all.
	if not show_endpoints and grain != "shell":
		return

	var mat := StandardMaterial3D.new()
	mat.albedo_color = line_color.lightened(0.3)
	mat.metallic = 0.7
	mat.roughness = 0.2
	mat.emission_enabled = true
	mat.emission = line_color
	mat.emission_energy_multiplier = 1.0

	var sphere := SphereMesh.new()
	sphere.radius = endpoint_radius
	sphere.height = endpoint_radius * 2.0
	sphere.radial_segments = 12
	sphere.rings = 6

	_endpoint_a = MeshInstance3D.new()
	_endpoint_a.name = "EndpointA"
	_endpoint_a.mesh = sphere
	_endpoint_a.material_override = mat
	_endpoint_a.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_endpoint_a)

	_endpoint_b = MeshInstance3D.new()
	_endpoint_b.name = "EndpointB"
	_endpoint_b.mesh = sphere.duplicate()
	_endpoint_b.material_override = mat
	_endpoint_b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_endpoint_b)


func _build_label() -> void:
	_length_label = Label3D.new()
	_length_label.name = "LengthLabel"
	_length_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_length_label.font_size = 28
	_length_label.modulate = Color(1.0, 1.0, 1.0, 0.8)
	_length_label.outline_size = 4
	_length_label.outline_modulate = Color(0.0, 0.0, 0.0, 1.0)
	_length_label.pixel_size = 0.001
	add_child(_length_label)


# ── Grain ────────────────────────────────────────────────────────────
#
# `solid` returns immediately: no node is added, no property is written, and
# the sixteen existing placements cannot tell this section exists. Every other
# rung hides the shipped rod and builds its pieces in a container of their own,
# so the endpoint beads, the label, the collider and the audio player are never
# touched and the resistance glitch keeps working on all five.

func _build_grain() -> void:
	if grain == "solid":
		return

	_parts_root = Node3D.new()
	_parts_root.name = "GrainParts"
	add_child(_parts_root)

	# The rod steps aside for every divided rung and for the boundary-only one.
	if _line_mesh:
		_line_mesh.visible = false

	var count: int = _grain_part_count()
	for i in range(count):
		var part := MeshInstance3D.new()
		part.name = "GrainPart%d" % i
		var cyl := CylinderMesh.new()
		cyl.top_radius = line_thickness
		cyl.bottom_radius = line_thickness
		cyl.radial_segments = 8
		cyl.rings = 0
		part.mesh = cyl
		# The literal same material resource as the rod, not a copy that drifts.
		part.material_override = _line_material
		part.rotation_degrees.z = 90.0
		part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_parts_root.add_child(part)
		_parts.append(part)

	_layout_parts()


## `shell` is the one rung that draws no body: the boundary points, built by
## _build_endpoints, and nothing between them.
func _grain_part_count() -> int:
	match grain:
		"split":
			return SPLIT_PARTS
		"quartered":
			return QUARTER_PARTS
		"lattice":
			return LATTICE_PARTS
		"shell":
			return 0
		_:
			return 0


## Equal pitch across the full length, so the outermost pieces still reach the
## endpoints and the envelope is the same at every rung.
func _layout_parts() -> void:
	var count: int = _parts.size()
	if count == 0:
		return
	var pitch: float = line_length / float(count)
	var part_len: float = pitch * (1.0 - PART_GAP_FRACTION)
	var half: float = line_length * 0.5
	for i in range(count):
		var cyl: CylinderMesh = _parts[i].mesh as CylinderMesh
		if cyl:
			cyl.height = part_len
		_parts[i].position = Vector3(-half + pitch * (float(i) + 0.5), 0.0, 0.0)


## Synchronous teardown + rebuild, and only ever called when the word actually
## moved. remove_child() first so the old pieces leave the tree in THIS frame —
## a deferred free would let the grid's auto-grounding measure a stale AABB.
func _rebuild_grain() -> void:
	_parts.clear()
	if is_instance_valid(_parts_root):
		if _parts_root.get_parent() == self:
			remove_child(_parts_root)
		_parts_root.queue_free()
	_parts_root = null

	# Un-hide the rod before the new rung decides what to do with it, or a
	# return to `solid` would leave an invisible line.
	if _line_mesh:
		_line_mesh.visible = true
		_line_mesh.position = Vector3.ZERO

	# Arriving at `shell` from a placement that had suppressed the beads.
	if _endpoint_a == null:
		_build_endpoints()

	_build_grain()
	_rebuild()


func _rebuild() -> void:
	var half := line_length / 2.0

	if _cylinder:
		_cylinder.height = line_length

	if _endpoint_a:
		_endpoint_a.position = Vector3(-half, 0, 0)
	if _endpoint_b:
		_endpoint_b.position = Vector3(half, 0, 0)

	if _length_label:
		_length_label.text = "%.2fm" % line_length
		_length_label.position = Vector3(0, 0.04, 0)

	# Update collision
	var col := get_node_or_null("LineCollision")
	if col and col.shape is CapsuleShape3D:
		var capsule: CapsuleShape3D = col.shape
		capsule.height = line_length + capsule.radius * 2.0

	# No-op on the shipped path — _parts is empty unless a rung built pieces.
	_layout_parts()


# ── Pickup ───────────────────────────────────────────────────────────

func _on_line_picked_up(_pickable) -> void:
	_is_held = true
	_current_controller = get_picked_up_by_controller()
	if _current_controller:
		_current_controller.trigger_haptic_pulse("haptic", 100.0, 0.4, 0.08, 0)
	# Glow brighter when held
	if _line_material:
		_line_material.emission_energy_multiplier = 1.5


func _on_line_dropped(_pickable) -> void:
	_is_held = false
	if _current_controller:
		_current_controller.trigger_haptic_pulse("haptic", 100.0, 0.2, 0.05, 0)
		_current_controller = null
	# Restore normal glow
	if _line_material:
		_line_material.emission_energy_multiplier = 0.8
	# Reset jitter
	if _line_mesh:
		_line_mesh.position = Vector3.ZERO
	if _parts_root:
		_parts_root.position = Vector3.ZERO


# ── Resistance Glitch ────────────────────────────────────────────────

func _process_position_resistance() -> void:
	# Glitch when the line's CENTER crosses near integer world coordinates
	var pos := global_position
	var axes := [pos.x, pos.y, pos.z]
	var max_intensity := 0.0

	for val in axes:
		var remainder: float = fmod(abs(val), 1.0)
		var dist_to_int: float = minf(remainder, 1.0 - remainder)
		if dist_to_int < resistance_threshold:
			var t: float = 1.0 - (dist_to_int / resistance_threshold)
			max_intensity = maxf(max_intensity, pow(t, 2.0))

	if max_intensity > 0.01:
		# Visual jitter
		if _line_mesh:
			var jitter := Vector3(
				randf_range(-1, 1),
				randf_range(-1, 1),
				randf_range(-1, 1)
			) * max_jitter * max_intensity
			_line_mesh.position = jitter
			# The divided rungs jitter as one body, exactly as the rod does.
			if _parts_root:
				_parts_root.position = jitter

			# Flash emission
			if randf() < max_intensity * 0.15:
				_line_material.emission_energy_multiplier = 4.0
			else:
				_line_material.emission_energy_multiplier = 1.5

		# Audio
		if _glitch_player:
			_glitch_player.volume_db = lerp(-40.0, glitch_sound_volume_db, max_intensity)
			_glitch_player.pitch_scale = 1.0 + (randf() - 0.5) * max_intensity

		# Haptic
		if _current_controller:
			var freq := 100.0 + max_intensity * 200.0
			_current_controller.trigger_haptic_pulse("haptic", freq, max_intensity * haptic_intensity_max, 0.05, 0)

		# Label glitch
		if _length_label and randf() < max_intensity * 0.2:
			_length_label.modulate = Color.RED
		elif _length_label:
			_length_label.modulate = Color(1.0, 1.0, 1.0, 0.8)
	else:
		# Reset
		if _line_mesh:
			_line_mesh.position = Vector3.ZERO
		if _parts_root:
			_parts_root.position = Vector3.ZERO
		if _glitch_player:
			_glitch_player.volume_db = -80.0
		if _length_label:
			_length_label.modulate = Color(1.0, 1.0, 1.0, 0.8)
		if _line_material:
			_line_material.emission_energy_multiplier = 1.5 if _is_held else 0.8


func _setup_glitch_audio() -> void:
	_glitch_stream = _generate_glitch_stream()
	_glitch_player = AudioStreamPlayer3D.new()
	_glitch_player.name = "GlitchPlayer"
	_glitch_player.stream = _glitch_stream
	_glitch_player.unit_size = 5.0
	_glitch_player.volume_db = -80.0
	_glitch_player.autoplay = true
	add_child(_glitch_player)


func _generate_glitch_stream() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var duration := 0.5
	var sample_count := int(stream.mix_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in sample_count:
		var sample: float = randf_range(-1.0, 1.0) * 0.8
		if randf() > 0.95:
			sample = sign(sample) * 1.0
		var int_sample: int = int(sample * 32767.0)
		data[2 * i] = int_sample & 0xFF
		data[2 * i + 1] = (int_sample >> 8) & 0xFF
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	return stream


# ── Public API ───────────────────────────────────────────────────────

func get_endpoint_a_global() -> Vector3:
	return _endpoint_a.global_position if _endpoint_a else global_position

func get_endpoint_b_global() -> Vector3:
	return _endpoint_b.global_position if _endpoint_b else global_position

func set_line_color(color: Color) -> void:
	line_color = color
	if _line_material:
		_line_material.albedo_color = color
		_line_material.emission = color


## Grid config entry point. Called by GridInteractablesComponent via
## call_deferred (after _ready), and by cluster_resolver / curation_station with
## dicts that carry no axis key at all. An unconditional rebuild there would
## throw away framing those callers had just applied, so the grain is only torn
## down when the word actually moved and the body has already been built once.
func apply_grid_config(config_data: Dictionary) -> void:
	var before_grain: String = grain

	if config_data.has("grain"):
		grain = _pick_grain(str(config_data["grain"]))
	if config_data.has("line_length"):
		line_length = config_data["line_length"]
	if config_data.has("line_color"):
		set_line_color(config_data["line_color"])
	if config_data.has("enable_resistance"):
		enable_resistance = config_data["enable_resistance"]

	if not _built:
		# Nothing exists yet; _ready() will build with the value just resolved.
		return
	if grain == before_grain:
		return
	_rebuild_grain()


func _read_metadata_overrides() -> void:
	if has_meta("config_grain"):
		grain = _pick_grain(str(get_meta("config_grain")))


## Accept an axis value only if it names something this artifact actually
## builds. Anything unrecognised keeps the value already held — for a fresh
## instance that is the shipped look.
func _pick_grain(raw: String) -> String:
	var want: String = raw.to_lower().strip_edges()
	return want if GRAINS.has(want) else grain
