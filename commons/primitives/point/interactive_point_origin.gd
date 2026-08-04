@tool
extends XRToolsPickable

# @identity
# essence: p = (x, y, z) — a position you can hold in your hand, relative to origin
# desire: learner feels coordinates as embodied distance from origin, not abstract numbers
# critical_parameter: the live line drawn to (0,0,0) while held — distance made visible
# triggers: pickup cycles through 4 coordinate display formats (decimal / integer / scientific / words)
# emerges: haptic pulse as a format-change event — the body learns before the mind
# needs: [has Label3D [has], grabbable (XRToolsPickable) [has], missing slider control]
# relationships: depends on origin; used alongside static_point to show pickable vs fixed
# truth: a coordinate is a measurement from origin — hold the point, feel the measurement

## Interactive point that shows position and draws line to origin when held


# Spine-corridor contract — see doc/SPINE_HINTS_CONTRACT.md
func spine_hints() -> Dictionary:
	return {
		"role":         "primary",
		"footprint":    Vector2i(2, 2),
		"approach":     "south",
		"reading_dist": 2.0,
		"height":       1.0,
		"budget_ms":    1.2,
		"tags":         ["vector", "interactive", "grouped"],
	}


# Visual feedback
@export var glow_color: Color = Color(1.0, 0.6, 1.0)
@export var glow_emission_energy: float = 2.0
@export var pickup_sound_volume_db: float = -6.0

# Line to origin settings
@export var line_color: Color = Color(0.3, 0.8, 1.0, 0.7)
@export var line_width: float = 0.003  # Very thin line
@export var origin_point: Vector3 = Vector3.ZERO

# Haptic feedback
@export var haptic_pickup_intensity: float = 0.5
@export var haptic_pickup_duration: float = 0.1
@export var haptic_drop_intensity: float = 0.3
@export var haptic_drop_duration: float = 0.05

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION — interactive_point_origin
#
#   mark   HOW A LOCATION WITH NO SIZE IS MADE VISIBLE
#          bead · crosshair · cage · halo
#
# WHAT WAS ALREADY TRUE. This is the primitives sequence's first object, and
# its identity says p = (x, y, z) — a position. A position has no extension.
# What stands in the room is a 60 mm ball with a light inside it, and every
# number the artifact prints is measured from a point somewhere in the middle
# of that ball. The ball is a lie about size, told so smoothly that the whole
# lesson is built on it and nobody meets the alternative. This axis is the
# alternatives: four claims about what the drawing of a point is FOR.
#
#   bead      (DEFAULT, the lineage) the solid pellet point_mesh.gd builds. A
#             location asserted as a small object you can pick up. It hides
#             that the thing has no size by giving it a comfortable one.
#   crosshair three thin bars along X, Y and Z crossing where the point is.
#             Nothing at the centre — the position is the INTERSECTION of its
#             three coordinates, and what you see is a reach rather than a
#             body. The lie moves from "it is a ball" to "it has directions".
#   cage      the twelve edges of the cell the point sits in, and nothing
#             inside. Extension is admitted and blamed on the GRID: this is
#             what a voxel world actually stores, an address with walls, and
#             the continuous position inside it is not drawn at all.
#   halo      a thin ring around a 4 mm speck. The visible mark declares
#             itself a mark — the size belongs to the drawing, not to the
#             thing — and the point itself is very nearly not there.
#
# WHY NOT THE LINE TO ORIGIN, which is this artifact's named critical
# parameter and the first axis anyone would reach for (float · always · ruler ·
# staircase, the coordinate decomposed into three legs). Two reasons, and the
# second is fatal. The line only exists WHILE HELD, and the evidence for an
# axis here is one still PNG of an object nobody is holding. And the sweep
# bench parents the artifact straight under the viewport, so global_position is
# (0,0,0) — it stands ON the origin, `distance < 0.001` returns early, and
# every value of such an axis would render the identical picture of no line at
# all. That is the "two values == 0.00% to the byte" failure with four values
# instead of two: a finished-looking experiment answering nothing. Declined on
# purpose, written down so the next reader does not rediscover it.
#
# NOR `readout`, the family word (none · numeral · gradation · lattice, shared
# by xyz_slider_plate and line for exactly this question). The four coordinate
# formats this file already cycles through on pickup are its natural values —
# and all four live in a Label3D that is `visible = false` until a hand closes
# on it. Invisible to a still, for the same reason, and the same decline.
#
# KIN. grab_sphere_F/E/lambda/phi carry `grasp` (atom · socket · chorus ·
# hollow · swarm) on a 24 mm sphere in this same folder, and that IS the
# neighbouring question — what your hand closes on. It is not this one: those
# spheres stand for TERMS OF A FORMULA, things with no referent at all, and
# `chorus` puts the other three terms on a rail. A coordinate has a perfectly
# good referent — a place — so the question here is not what a term is but how
# a place is marked. Different subject, different word, and the value lists do
# not overlap.
#
# NOT ROUTED THROUGH mark: the collision sphere, the pickable contract, the
# grab, the haptics, the pickup tone, the origin line, the label and its four
# formats, the highlight ring and the OmniLight are all untouched. Only the
# body you look at changes; everything you do with it is the same.
# ─────────────────────────────────────────────────────────────────────────────

## THE AXIS. bead is the legacy lineage and builds nothing new. The registry
## declaration is derived from THIS LINE by tools/apply_dna_block.py.
@export_enum("bead", "crosshair", "cage", "halo") var mark: String = "bead"

## The allow-list a map token is checked against. An unknown word falls back to
## the shipped bead rather than stranding a placement with no body at all.
const MARKS: PackedStringArray = ["bead", "crosshair", "cage", "halo"]

## Span of the non-bead marks, in metres. Sized to the bead it replaces (60 mm)
## so the point stays a point and the axis is not a size dial in disguise.
const MARK_SPAN: float = 0.12
const MARK_BAR: float = 0.006
const MARK_CELL: float = 0.10

# Internal references
var _original_material: Material
var _glow_material: Material
var _pickup_player: AudioStreamPlayer3D
var _pickup_stream: AudioStreamWAV
var _is_glowing := false
var _current_controller: XRController3D

# Line to origin
var _line_mesh_instance: MeshInstance3D
var _line_material: StandardMaterial3D
var _line_cylinder: CylinderMesh
var _last_line_distance: float = -1.0
var _is_held := false

# Position label
var _position_label: Label3D
var _display_format_index: int = 2 # Start at 2 so first pickup cycles to 0 (default)

# Mark
var _mark_built := false

func _ready() -> void:
	super()

	# Get mesh and materials — start glowing so point is visible in dark scenes
	var mesh_instance = get_node_or_null("MeshInstance3D")
	if mesh_instance:
		_original_material = mesh_instance.get_active_material(0)
		_glow_material = _build_glow_material(_original_material)
		mesh_instance.material_override = _glow_material
		_is_glowing = true

	# Setup audio
	_setup_pickup_audio()
	
	# Setup line to origin
	_setup_line_to_origin()
	
	# Find or create position label
	_position_label = get_node_or_null("MeshInstance3D/Label3D")
	if _position_label:
		_position_label.visible = false  # Hidden until picked up
	
	# Connect signals
	picked_up.connect(_on_picked_up)
	dropped.connect(_on_dropped)

	# The body. At bead this touches nothing that was not already here.
	_read_mark()
	_build_mark()
	_mark_built = true

## A map token reaches here as metadata the grid stamps before add_child; the
## sweep sets the export directly, so the export is the fallback.
func _read_mark() -> void:
	var want: String = mark
	if has_meta("config_mark"):
		want = str(get_meta("config_mark"))
	elif has_meta("mark"):
		want = str(get_meta("mark"))
	mark = _normalise_mark(want)

func _normalise_mark(raw: String) -> String:
	var word: String = raw.strip_edges().to_lower()
	if MARKS.has(word):
		return word
	return "bead"

## Rebuild ONLY when a map actually changed the value and _ready has already
## built once. An unguarded rebuild here would tear the body off every shipped
## placement to end up exactly where it started.
func apply_grid_config(config_data: Dictionary) -> void:
	if not config_data.has("mark"):
		return
	var want: String = _normalise_mark(str(config_data["mark"]))
	if want == mark:
		return
	mark = want
	if not _mark_built:
		return
	_build_mark()

## The legacy bead IS the host MeshInstance3D (point_mesh.gd wrote a sphere into
## it before this _ready ran). The other three marks hang under it in a `Mark`
## node, so the ROOT's direct children — what GridInteractablesComponent walks
## to ground an artifact on the floor — are the same set they have always been.
##
## The bead is retired with `layers = 0` and not `visible = false`: visibility
## propagates and would take the Label3D and the OmniLight down with it, and the
## light going out would change the room. layers is per-instance and leaves the
## surface override material the glow/restore path swaps in place.
func _build_mark() -> void:
	var host: MeshInstance3D = get_node_or_null("MeshInstance3D") as MeshInstance3D
	if host == null:
		return
	var old: Node = host.get_node_or_null("Mark")
	if old != null:
		host.remove_child(old)
		old.queue_free()
	if mark == "bead":
		host.layers = 1
		return
	host.layers = 0
	var holder := Node3D.new()
	holder.name = "Mark"
	host.add_child(holder)
	match mark:
		"crosshair":
			_build_crosshair(holder)
		"cage":
			_build_cage(holder)
		"halo":
			_build_halo(holder)

## Same palette the bead is lit with, so the axis is about form and not colour.
func _build_mark_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.95, 0.92)
	mat.emission_enabled = true
	mat.emission = glow_color
	mat.emission_energy_multiplier = glow_emission_energy * 0.6
	return mat

func _build_bar(holder: Node3D, size: Vector3, at: Vector3, mat: StandardMaterial3D) -> void:
	var bar := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	bar.mesh = box
	bar.material_override = mat
	bar.position = at
	bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(bar)

## Three axes crossing, nothing at the crossing.
func _build_crosshair(holder: Node3D) -> void:
	var mat := _build_mark_material()
	_build_bar(holder, Vector3(MARK_SPAN, MARK_BAR, MARK_BAR), Vector3.ZERO, mat)
	_build_bar(holder, Vector3(MARK_BAR, MARK_SPAN, MARK_BAR), Vector3.ZERO, mat)
	_build_bar(holder, Vector3(MARK_BAR, MARK_BAR, MARK_SPAN), Vector3.ZERO, mat)

## The twelve edges of the cell, and nothing inside it.
func _build_cage(holder: Node3D) -> void:
	var mat := _build_mark_material()
	var half: float = MARK_CELL * 0.5
	var t: float = MARK_BAR * 0.85
	for a in range(2):
		for b in range(2):
			var sa: float = -half if a == 0 else half
			var sb: float = -half if b == 0 else half
			_build_bar(holder, Vector3(MARK_CELL, t, t), Vector3(0.0, sa, sb), mat)
			_build_bar(holder, Vector3(t, MARK_CELL, t), Vector3(sa, 0.0, sb), mat)
			_build_bar(holder, Vector3(t, t, MARK_CELL), Vector3(sa, sb, 0.0), mat)

## A ring that owns the visible size, and a speck that owns the position.
func _build_halo(holder: Node3D) -> void:
	var mat := _build_mark_material()
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = MARK_SPAN * 0.43
	torus.outer_radius = MARK_SPAN * 0.5
	ring.mesh = torus
	ring.material_override = mat
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(ring)
	var speck := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.004
	sphere.height = 0.008
	speck.mesh = sphere
	speck.material_override = mat
	holder.add_child(speck)

func _process(_delta: float) -> void:
	if _is_held:
		_update_line_to_origin()
		_update_position_label()

func _setup_line_to_origin() -> void:
	# Create line mesh instance
	_line_mesh_instance = MeshInstance3D.new()
	_line_mesh_instance.name = "LineToOrigin"
	_line_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_line_mesh_instance.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	add_child(_line_mesh_instance)
	
	# Reuse one mesh to avoid per-frame allocations while held in VR
	_line_cylinder = CylinderMesh.new()
	_line_cylinder.height = 0.001
	_line_cylinder.top_radius = line_width
	_line_cylinder.bottom_radius = line_width
	_line_cylinder.radial_segments = 6
	_line_cylinder.rings = 1
	_line_mesh_instance.mesh = _line_cylinder
	
	# Create material for line
	_line_material = StandardMaterial3D.new()
	_line_material.albedo_color = line_color
	_line_material.emission_enabled = true
	_line_material.emission = line_color
	_line_material.emission_energy_multiplier = 1.5
	_line_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_line_material.disable_receive_shadows = true
	_line_material.no_depth_test = true
	
	_line_mesh_instance.material_override = _line_material
	_line_mesh_instance.visible = false

func _update_line_to_origin() -> void:
	if not _line_mesh_instance:
		return
	
	var current_pos: Vector3 = global_position
	var direction: Vector3 = origin_point - current_pos
	var distance: float = direction.length()
	
	if distance < 0.001:
		_line_mesh_instance.visible = false
		return
	
	_line_mesh_instance.visible = true

	if _line_cylinder:
		if absf(distance - _last_line_distance) > 0.0005:
			_line_cylinder.height = distance
			_last_line_distance = distance
		_line_cylinder.top_radius = line_width
		_line_cylinder.bottom_radius = line_width
	
	# Position at midpoint between current position and origin
	var midpoint: Vector3 = (current_pos + origin_point) / 2.0
	_line_mesh_instance.global_position = midpoint
	
	# Rotate to point from current position to origin
	var up: Vector3 = Vector3.UP
	if abs(direction.normalized().dot(up)) > 0.99:
		up = Vector3.RIGHT
	
	_line_mesh_instance.look_at(origin_point, up)
	_line_mesh_instance.rotate_object_local(Vector3.RIGHT, PI / 2.0)

func _update_position_label() -> void:
	if not _position_label:
		return
	
	var pos = global_position
	match _display_format_index:
		0:
			_position_label.visible = true
			_position_label.text = "(%.2f, %.2f, %.2f)" % [pos.x, pos.y, pos.z]
		1:
			_position_label.visible = true
			_position_label.text = "(x:%.2f, y:%.2f, z:%.2f)" % [pos.x, pos.y, pos.z]
		2:
			_position_label.visible = true
			_position_label.text = "Vector3(%.2f, %.2f, %.2f)" % [pos.x, pos.y, pos.z]
		3:
			_position_label.visible = false

func _build_glow_material(source: Material) -> Material:
	var material := source
	if material:
		material = material.duplicate()
	else:
		material = StandardMaterial3D.new()
	
	if material is BaseMaterial3D:
		var base_mat := material as BaseMaterial3D
		base_mat.emission_enabled = true
		base_mat.emission = glow_color
		base_mat.emission_energy_multiplier = glow_emission_energy
		base_mat.albedo_color = base_mat.albedo_color.lerp(glow_color, 0.3)
	
	return material

func _setup_pickup_audio() -> void:
	_pickup_stream = _build_pickup_stream()
	_pickup_player = AudioStreamPlayer3D.new()
	_pickup_player.name = "PickupPlayer"
	_pickup_player.stream = _pickup_stream
	_pickup_player.autoplay = false
	_pickup_player.volume_db = pickup_sound_volume_db
	_pickup_player.unit_size = 0.5
	_pickup_player.attenuation_filter_cutoff_hz = 6000
	add_child(_pickup_player)

func _build_pickup_stream() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var duration := 0.18
	var tone := 880.0
	var length := int(stream.mix_rate * duration)
	var data := PackedByteArray()
	data.resize(length * 2)
	for i in length:
		var t: float = float(i) / stream.mix_rate
		var envelope: float = min(t / 0.02, 1.0) * exp(-3.0 * t)
		var sample: float = sin(TAU * tone * t) * 0.45 * envelope
		var int_sample: int = int(sample * 32767.0)
		data[2 * i] = int_sample & 0xFF
		data[2 * i + 1] = (int_sample >> 8) & 0xFF
	stream.data = data
	return stream

func _apply_glow() -> void:
	if not _glow_material:
		_glow_material = _build_glow_material(_original_material)
	_is_glowing = true
	var mesh_instance = get_node_or_null("MeshInstance3D")
	if mesh_instance:
		mesh_instance.set_surface_override_material(0, _glow_material)

func _restore_original_material() -> void:
	_is_glowing = false
	var mesh_instance = get_node_or_null("MeshInstance3D")
	if mesh_instance:
		mesh_instance.set_surface_override_material(0, _original_material)

func _play_pickup_sound() -> void:
	if not _pickup_player:
		return
	if _pickup_player.playing:
		_pickup_player.stop()
	_pickup_player.play()

func _trigger_haptic(controller: XRController3D, intensity: float, duration: float) -> void:
	if controller:
		controller.trigger_haptic_pulse("haptic", 100.0, intensity, duration, 0)

func _on_picked_up(_pickable) -> void:
	# Cycle through display formats (0 -> 1 -> 2 -> 3 -> 0)
	_display_format_index = (_display_format_index + 1) % 4

	_current_controller = get_picked_up_by_controller()
	if _current_controller:
		_trigger_haptic(_current_controller, haptic_pickup_intensity, haptic_pickup_duration)
	
	_apply_glow()
	_play_pickup_sound()
	_is_held = true
	
	# Show position label
	if _position_label:
		_position_label.visible = true
	
	# Show line to origin
	if _line_mesh_instance:
		_line_mesh_instance.visible = true

func _on_dropped(_pickable) -> void:
	if _current_controller:
		_trigger_haptic(_current_controller, haptic_drop_intensity, haptic_drop_duration)
		_current_controller = null
	
	_restore_original_material()
	_is_held = false
	
	# Hide position label
	if _position_label:
		_position_label.visible = false
	
	# Hide line to origin
	if _line_mesh_instance:
		_line_mesh_instance.visible = false
