# pickup_gate.gd
# A gate/portal that blocks passage until a certain number of pickup cubes are collected
# Instantiated like: pickup_gate#pickups:5 or pickup_gate#count:3

extends Node3D

class_name PickupGate

# Parameters - set via grid instantiation
@export var required_pickups: int = 1  # Number of pickups needed to open the gate
@export var gate_color: Color = Color(1.0, 0.0, 0.0, 0.5)  # Red semi-transparent by default
@export var gate_open_color: Color = Color(0.0, 1.0, 0.0, 0.3)  # Green transparent when open

## STAGE-2 DNA — AXIS: notice (2026-08-03)
##
## HOW THE GATE GIVES NOTICE OF ITS OWN CONDITION. The gate is the curriculum's first
## piece of conditional infrastructure: a wall that is a rule. Its geometry is one box —
## the whole argument lives in what the wall tells you about the price of passing it, and
## today it tells you in digits, because a Label3D printing "Collect 3 more (2/5)" is the
## only thing the shipped scene has ever said. That is one answer out of five, and it was
## never chosen: it is what a debug label became.
##
##   count    the numeric tally over the gate — "Collect 3 more (2/5)". A price posted in
##            digits. The legacy lineage, byte for byte
##   none     nothing at all. A shut red wall that never states its terms; you learn the
##            rule by carrying things at it until it moves. The label returns only at the
##            moment the gate opens, which is the only thing it has left to say
##   gauge    a plain trough that fills. Nearness without a number: you can see you are
##            close and you cannot see what it costs
##   slots    one empty socket per required pickup, filled as they arrive. The demand as
##            countable vacancies rather than a figure — you read it by looking, not by
##            reading
##   barrier  no readout anywhere. The wall itself is banded into one layer per pickup and
##            sheds a layer each time one crosses. The obstacle IS the statement
##
## NOT the `readout` ladder that line / line_interface / xyz_slider_plate share. That word
## is honest about a continuous value you are SETTING, and its fourth rung, `lattice`,
## means "the privileged whole-number set drawn standing". A count has no privileged
## subset — every value it can hold is already a whole number — so that rung collapses
## here, and the family's fourth claim would have to be faked. This artifact also has a
## possibility no measuring instrument has: it owns a BARRIER, and the barrier can be the
## readout. Different question, different word.
##
## APPEARANCE ONLY. Nothing below touches required_pickups, the GameManager score, the
## collision body, _open_gate() or _close_gate(). A variant changes what the wall SAYS
## about its condition, never what the condition is.
@export_enum("count", "none", "gauge", "slots", "barrier") var notice: String = "count"
const NOTICES: PackedStringArray = ["count", "none", "gauge", "slots", "barrier"]

# Internal state
var is_open: bool = false
var blocking_mesh: MeshInstance3D = null
var collision_body: StaticBody3D = null
var collision_shape: CollisionShape3D = null
var label: Label3D = null

func _ready() -> void:
	print("PickupGate: Initialized, requires %d pickups" % required_pickups)

	# Find child nodes
	blocking_mesh = find_child("BlockingMesh", true, false) as MeshInstance3D
	collision_body = find_child("StaticBody3D", true, false) as StaticBody3D
	collision_shape = find_child("CollisionShape3D", true, false) as CollisionShape3D
	label = find_child("Label3D", true, false) as Label3D

	# Connect to GameManager signals
	if GameManager:
		GameManager.score_updated.connect(_on_score_updated)
	else:
		push_error("PickupGate: GameManager not found!")

	# The notice is built LAST, after the children exist, so it can hide the label and
	# band the wall. _notice_built flips only here: a config key that arrives before
	# _ready has run sets the value and lets _ready do the one build.
	_notice_read_config()
	_notice_build()
	_notice_built = true

	# Defer initial check to allow configuration to be applied first
	call_deferred("_initial_gate_check")

func _initial_gate_check() -> void:
	# Called deferred after _ready() to allow configuration to be applied first
	print("PickupGate: Performing initial gate check with %d required pickups" % required_pickups)
	if GameManager:
		_check_and_update_gate(GameManager.get_score())
	_update_label()

func _on_score_updated(new_score: int) -> void:
	print("PickupGate: Score updated to %d (need %d)" % [new_score, required_pickups])
	_check_and_update_gate(new_score)

func _check_and_update_gate(current_score: int) -> void:
	if current_score >= required_pickups and not is_open:
		_open_gate()
	elif current_score < required_pickups and is_open:
		_close_gate()

	# Always update the label
	_update_label()
	# ...and whatever the notice axis is saying instead of it. No-op on `count`.
	_notice_refresh()

func _open_gate() -> void:
	is_open = true
	print("PickupGate: OPENING GATE!")

	# Remove collision body IMMEDIATELY (so player can pass through right away)
	if collision_body and is_instance_valid(collision_body):
		print("  Removing collision body...")
		# Disable collision layers instantly (belt and suspenders approach)
		collision_body.collision_layer = 0
		collision_body.collision_mask = 0
		# Then queue for removal
		collision_body.queue_free()
		collision_body = null
		collision_shape = null
	else:
		print("  WARNING: collision_body not found!")

	# Remove blocking mesh
	if blocking_mesh and is_instance_valid(blocking_mesh):
		# Just remove it directly - no fade animation with shader materials
		blocking_mesh.queue_free()
		blocking_mesh = null

	# The notice has nothing left to disclose — the condition is met and the wall is gone.
	# On `count` there is no notice geometry, so this is a no-op for the legacy path.
	_notice_clear()

	# Update label
	_update_label()

	# Play open sound
	_play_open_sound()

func _close_gate() -> void:
	is_open = false
	print("PickupGate: CLOSING GATE")

	# Show blocking mesh
	if blocking_mesh:
		blocking_mesh.visible = true
		blocking_mesh.modulate.a = gate_color.a

	# Enable collision
	if collision_shape:
		collision_shape.disabled = false

	# Update label
	_update_label()

func _update_label() -> void:
	if not label:
		return

	var current_score = 0
	if GameManager:
		current_score = GameManager.get_score()

	if is_open:
		label.text = "GATE OPEN\n✓"
		label.modulate = Color.GREEN
	else:
		var remaining = required_pickups - current_score
		label.text = "Collect %d more\n(%d/%d)" % [remaining, current_score, required_pickups]
		label.modulate = Color.ORANGE

	# The one line the notice axis adds to the legacy path. On `count` this evaluates to
	# true always, which is the label's own default, so the two shipped placements render
	# exactly as before. Every other value speaks through geometry instead — and all of
	# them let the label back the instant the gate opens, because "OPEN" is the one thing
	# a gate that refused to state its terms still owes you.
	label.visible = is_open or notice == "count"

func _play_open_sound() -> void:
	# Create a simple success sound
	var sound_player = AudioStreamPlayer3D.new()
	add_child(sound_player)

	sound_player.unit_size = 5.0
	sound_player.max_distance = 30.0
	sound_player.volume_db = -3.0

	# Generate a rising tone success sound
	var sample_rate = 44100
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate

	var data = PackedByteArray()
	var duration = 0.4
	var samples = int(duration * sample_rate)

	for i in range(samples):
		var t = float(i) / sample_rate
		var progress = t / duration

		# Rising frequency sweep
		var freq = lerp(440.0, 880.0, progress)
		var envelope = (1.0 - progress) * 0.6  # Fade out

		var sample_value = sin(TAU * freq * t) * envelope
		var sample_int = int(sample_value * 32767.0)
		data.append(sample_int & 0xFF)
		data.append((sample_int >> 8) & 0xFF)

	stream.data = data
	sound_player.stream = stream
	sound_player.play()

	# Clean up after playing
	sound_player.finished.connect(func(): sound_player.queue_free())

# Public API - called by GridInteractablesComponent to set parameters
func set_required_pickups(count: int) -> void:
	required_pickups = max(1, count)
	print("PickupGate: Required pickups set to %d" % required_pickups)
	_update_label()

# Helper for grid spawning - parse parameters from token like "pickup_gate:5"
func parse_parameters(params: Array) -> void:
	if params.size() > 0:
		var count_str = str(params[0])
		if count_str.is_valid_int():
			set_required_pickups(int(count_str))

# Called by GridInteractablesComponent when using # syntax
# Supports: pickup_gate#pickups:5 or pickup_gate#count:3
func apply_grid_config(config: Dictionary) -> void:
	print("PickupGate: Applying grid config: %s" % config)

	# Check for pickup count configuration
	if config.has("pickups"):
		var count_str = str(config["pickups"])
		if count_str.is_valid_int():
			set_required_pickups(int(count_str))
			print("  Set required pickups from 'pickups' key: %d" % required_pickups)

	# Also support "count" as alias
	if config.has("count"):
		var count_str = str(config["count"])
		if count_str.is_valid_int():
			set_required_pickups(int(count_str))
			print("  Set required pickups from 'count' key: %d" % required_pickups)

	# Support color configuration
	if config.has("color"):
		var color_str = str(config["color"]).to_lower()
		match color_str:
			"red":
				gate_color = Color(1.0, 0.0, 0.0, 0.5)
			"blue":
				gate_color = Color(0.0, 0.0, 1.0, 0.5)
			"green":
				gate_color = Color(0.0, 1.0, 0.0, 0.5)
			"yellow":
				gate_color = Color(1.0, 1.0, 0.0, 0.5)

		# Update mesh color if already created
		if blocking_mesh and blocking_mesh.material_override:
			blocking_mesh.material_override.albedo_color = gate_color

	# How the gate gives notice of its condition. Gated on the key AND on the value
	# actually changing: a map that says nothing about `notice` — which is every map that
	# places this today — never reaches a rebuild, so the legacy wall cannot be disturbed
	# by a config carrying only pickups/count/color.
	if config.has("notice"):
		var want: String = str(config["notice"]).strip_edges().to_lower()
		if NOTICES.has(want) and want != notice:
			notice = want
			# Only after _ready has built once. Arriving earlier, the value alone is
			# enough — _ready does the single build with it.
			if _notice_built:
				_notice_build()

	# Re-check gate state after configuration is applied
	if GameManager:
		_check_and_update_gate(GameManager.get_score())
	_update_label()


# ── NOTICE ───────────────────────────────────────────────────────────────────────────
# One axis, five ways a rule can be posted on the wall that enforces it. Appended LAST:
# the blocking mesh, the collision body and the label are all built by the scene above,
# and the default value leaves every one of them exactly as it found them.
#
# WHERE THE GEOMETRY GOES. The scene's blocking box is a 1 m cube seated at y = 1 and the
# label floats at y = 2.5; the readouts sit in the gap between them, on the front face, so
# choosing a value changes what is on the wall and never how much room the gate occupies.
#
# LEGIBILITY, not taste. A demand of 40 pickups cannot be forty sockets you can count in a
# still, so the countable forms clamp at NOTICE_MAX_UNITS and the gauge — which is a
# proportion and does not care how many — carries any number. Clamping is a reading
# decision made in the open, not a lie: the trough is still exact.

const NOTICE_MAX_UNITS: int = 12
const NOTICE_Y: float = 1.80          # between the top of the box (1.5) and the label (2.5)
const NOTICE_Z: float = 0.56          # just proud of the front face
const NOTICE_SPAN: float = 0.92       # the readouts stay inside the gate's own footprint

var _notice_node: Node3D = null
var _notice_built: bool = false


## The grid stamps `pickup_gate#notice:slots` onto the node as metadata before _ready.
func _notice_read_config() -> void:
	if has_meta("config_notice"):
		var raw: String = str(get_meta("config_notice")).strip_edges().to_lower()
		if NOTICES.has(raw):
			notice = raw


## Detached BEFORE queue_free, not just queued. _notice_refresh() rebuilds on every score
## change, and a queued node is still a child for the rest of the frame — so the fresh
## root would collide on the name, Godot would rename it "GateNotice2", and for one frame
## the gate would carry two overlapping readouts drawn at two different counts.
func _notice_clear() -> void:
	if is_instance_valid(_notice_node):
		if _notice_node.get_parent() == self:
			remove_child(_notice_node)
		_notice_node.queue_free()
	_notice_node = null


func _notice_build() -> void:
	_notice_clear()

	# The banded wall is the only value that touches the shipped mesh, and it hides it with
	# `layers = 0` rather than `visible = false`. Visibility is hierarchical in Godot and
	# _close_gate() sets `visible = true` on this node when a gate re-closes, which would
	# silently restore the solid box under the bands; the render layer is per-instance,
	# nothing else in this file writes it, and the mesh and material are left untouched.
	if is_instance_valid(blocking_mesh):
		blocking_mesh.layers = 0 if notice == "barrier" else 1

	match notice:
		"count":
			pass                      # the legacy lineage — the label, and nothing else
		"none":
			pass                      # a shut wall that states no terms
		"gauge":
			_notice_gauge()
		"slots":
			_notice_slots()
		"barrier":
			_notice_barrier()
		_:
			pass                      # an unrecognised word reads as the legacy count

	# The label follows the axis — but ONLY off the legacy path. _update_label() rewrites
	# the label's text, and the shipped scene carries the placeholder "Collect pickups"
	# until the deferred _initial_gate_check() replaces it with a configured count. Calling
	# it here on `count` would overwrite that placeholder one frame early, with an
	# un-configured required_pickups. Same final text, one different frame — and "the
	# default renders exactly as before" has to mean every frame, not the last one.
	if notice != "count":
		_update_label()


## Redraw whatever the axis is showing, at the score it is showing it at. Cheap enough to
## rebuild wholesale — these are a dozen boxes — and rebuilding avoids keeping a parallel
## model of which unit is lit. Returns immediately on the legacy path and once open.
func _notice_refresh() -> void:
	if notice == "count" or notice == "none" or is_open:
		return
	if not _notice_built:
		return
	_notice_build()


func _notice_root() -> Node3D:
	if not is_instance_valid(_notice_node):
		_notice_node = Node3D.new()
		_notice_node.name = "GateNotice"
		add_child(_notice_node)
	return _notice_node


## How much of the demand is already met, clamped into the demand's own range. READ ONLY —
## the readouts report the score, they never touch it.
func _notice_have() -> int:
	var score: int = 0
	if GameManager:
		score = GameManager.get_score()
	return clampi(score, 0, maxi(required_pickups, 1))


func _notice_units() -> int:
	return clampi(required_pickups, 1, NOTICE_MAX_UNITS)


func _notice_mat(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.55
	if energy > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = energy
	return m


func _notice_box(nm: String, size: Vector3, at: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = at
	_notice_root().add_child(mi)


## GAUGE — a plain trough that fills. No digits and no divisions, so the wall tells you how
## NEAR you are and refuses to tell you what it costs. Nearness is not a price.
func _notice_gauge() -> void:
	var h: float = 0.15
	var dark: StandardMaterial3D = _notice_mat(Color(0.09, 0.10, 0.12), 0.0)
	var rim: StandardMaterial3D = _notice_mat(Color(0.42, 0.45, 0.50), 0.0)
	_notice_box("GaugeTrough", Vector3(NOTICE_SPAN, h, 0.05),
		Vector3(0.0, NOTICE_Y, NOTICE_Z), dark)
	_notice_box("GaugeRimTop", Vector3(NOTICE_SPAN, 0.015, 0.062),
		Vector3(0.0, NOTICE_Y + h * 0.5, NOTICE_Z), rim)
	_notice_box("GaugeRimBottom", Vector3(NOTICE_SPAN, 0.015, 0.062),
		Vector3(0.0, NOTICE_Y - h * 0.5, NOTICE_Z), rim)

	var frac: float = float(_notice_have()) / float(maxi(required_pickups, 1))
	if frac <= 0.001:
		return
	var inner: float = NOTICE_SPAN - 0.03
	var w: float = inner * frac
	_notice_box("GaugeFill", Vector3(w, h - 0.03, 0.07),
		Vector3(-inner * 0.5 + w * 0.5, NOTICE_Y, NOTICE_Z),
		_notice_mat(Color(0.25, 0.85, 0.45), 1.4))


## SLOTS — one socket per pickup the gate wants, filled as they arrive. The demand as a set
## of vacancies: you read it by looking at empty places, never by reading a number.
func _notice_slots() -> void:
	var n: int = _notice_units()
	var have: int = _notice_have()
	var pitch: float = NOTICE_SPAN / float(n)
	var s: float = minf(pitch * 0.72, 0.15)
	var rim: StandardMaterial3D = _notice_mat(Color(0.42, 0.45, 0.50), 0.0)
	var hole: StandardMaterial3D = _notice_mat(Color(0.07, 0.08, 0.09), 0.0)
	var full: StandardMaterial3D = _notice_mat(Color(0.25, 0.85, 0.45), 1.6)
	for i in range(n):
		var x: float = -NOTICE_SPAN * 0.5 + pitch * (float(i) + 0.5)
		_notice_box("SlotRim%d" % i, Vector3(s, s, 0.04),
			Vector3(x, NOTICE_Y, NOTICE_Z), rim)
		var filled: bool = i < have
		_notice_box("SlotCore%d" % i, Vector3(s * 0.62, s * 0.62, 0.06),
			Vector3(x, NOTICE_Y, NOTICE_Z), full if filled else hole)


## BARRIER — no readout anywhere. The wall is banded into one layer per pickup and drops a
## layer each time one crosses, so the count is legible only as how much wall is left. The
## obstacle and the announcement are the same object.
func _notice_barrier() -> void:
	var n: int = _notice_units()
	var have: int = _notice_have()
	var band_h: float = 1.0 / float(n)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = gate_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(gate_color.r, gate_color.g, gate_color.b)
	mat.emission_energy_multiplier = 0.5
	for i in range(n):
		if i < have:
			continue          # this layer has been paid for and is gone
		var y: float = 0.5 + band_h * (float(i) + 0.5)
		_notice_box("Band%d" % i, Vector3(1.0, band_h * 0.76, 1.0),
			Vector3(0.0, y, 0.0), mat)
