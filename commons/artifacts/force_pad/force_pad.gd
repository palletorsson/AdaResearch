extends Node3D
class_name ForcePad

# @identity
# essence: a 1x1 m launch pad — step on it and it throws you UP and FORWARD on a
#          ballistic arc. A force vector you trigger with your feet.
# desire: to make impulse bodily — the instant you touch the plate, gravity hands
#         you a velocity (up + forward) and the room rushes past.
# critical_parameter: up_force + forward_force — the two components of the launch
#         velocity v0 = forward*f̂ + up*ŷ; together they set the arc and the range.
# triggers: Area3D on the player_body layer (mask 524288); on enter, set the VR
#           player CharacterBody3D's velocity (the jump_pad / human_catapult path).
# emerges: locomotion as a vector sum — the chevrons + the glowing arrow show the
#          exact direction you'll fly before you commit your feet.
# truth: a launch is just a velocity you're given; gravity does the rest.

const PLAYER_MASK := 524288   # player body physics layer 20

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-08-03). Eight placements, and every knob it had was
# a MAGNITUDE — how hard, how high, how long the cooldown. Numbers, not arguments:
# turning them made the same pad launch you further. The launch itself is an
# EVENT and the evidence for this loop is one still, so the throw could never be
# the axis. What a still CAN hold is what the pad SAYS before you step on it.
#
# TWO AXES, BOTH THE CATAPULT'S WORDS, character for character. force_pad and
# catapult are the same machine at two scales — both hand a body a velocity and
# let gravity have it back — and catapult already split that question in two:
#
#   foresight   how much of the ARC is handed to you before you fire
#               parabola · apex · landing · none
#   vectors     how "what you give" is drawn at the launch point
#               sum · components · velocity · gravity
#
# The one thing that changes is the DEFAULT, and it changes because the two
# machines shipped at opposite ends of the same ladder. The catapult was born
# showing its whole parabola; the force pad was born showing NONE of it — the
# arrow says which way and how hard, and where you come down was never drawn.
# So foresight=none and vectors=velocity are the shipped pad exactly, and all
# eight placements keep the plate, the chevrons and the one cyan arrow they have.
#
# WHAT EACH VALUE ARGUES, because a launch pad that draws its own landing ring is
# not a prettier launch pad, it is a different claim about consent: at `none` you
# commit your feet and find out; at `landing` the floor already says where you
# will be standing; at `parabola` the whole flight is written before you move.
# The pad stops being a trap and becomes an instrument, or the other way round.
#
# NOT TOUCHED: the Area3D, the mask, the velocity handed to the player body, the
# cooldown, the pulse. Nothing here changes where anybody flies — only what the
# pad admits about it beforehand.
# ─────────────────────────────────────────────────────────────────────────────

## The catapult's ladder, same word and same four values. `none` is the legacy pad.
@export_enum("parabola", "apex", "landing", "none") var foresight: String = "none"
## The catapult's second word, same four values. `velocity` — one arrow for the
## throw, gravity left unstated — is what the pad has always drawn.
@export_enum("sum", "components", "velocity", "gravity") var vectors: String = "velocity"

const FORESIGHTS: PackedStringArray = ["parabola", "apex", "landing", "none"]
const VECTOR_DRAWINGS: PackedStringArray = ["sum", "components", "velocity", "gravity"]

@export var forward_force: float = 6.0    # m/s along the pad's forward (+Z)
@export var up_force: float = 7.0          # m/s upward
@export var cooldown_time: float = 0.8
@export var pad_color: Color = Color(0.12, 0.92, 1.0)
## Only ever READ, never applied — the pad hands the player body a velocity and
## the player's own controller does the falling. This is the g the drawn arc is
## drawn with, so the prediction matches the room the pad stands in.
@export var gravity_magnitude: float = 9.8

## Where the launch vector is drawn from, in pad-local space. The arc, the apex
## cross and the arrows all start here, so they cannot drift apart.
const LAUNCH_ORIGIN := Vector3(0.0, 0.2, 0.0)
const GRAVITY_COLOR := Color(0.95, 0.45, 0.25)

var _pad_mat: StandardMaterial3D
var _arrow: Node3D
var _arrow_up: Node3D          # vectors:components — the vertical part
var _arrow_g: Node3D           # vectors:sum|gravity — the constant given
var _foresight_mesh: ImmediateMesh
var _cooldown: float = 0.0
var _pulse_t: float = 0.0
var _built: bool = false
var _accent_mats: Array[StandardMaterial3D] = []


func _ready() -> void:
	_build_pad()
	_build_arrow()
	_build_area()
	_refresh_arrow()
	_build_foresight()
	_built = true


## Map tokens: "force_pad#foresight:landing", "force_pad#vectors:components".
##
## GUARDED. The shipped version freed every child and re-ran _ready() on ANY call,
## even one whose dictionary named nothing this pad owns — eight placements torn
## down and rebuilt for nothing, and a rebuild scheduled before the first build had
## happened at all. Now it rebuilds only when a value actually changed and only
## after _ready has run once; cooldown_time never rebuilds, because it changes no
## geometry.
func apply_grid_config(config: Dictionary) -> void:
	var rebuild: bool = false
	if config.has("foresight"):
		var f: String = _pick_axis(str(config["foresight"]), FORESIGHTS, foresight)
		if f != foresight:
			foresight = f
			rebuild = true
	if config.has("vectors"):
		var v: String = _pick_axis(str(config["vectors"]), VECTOR_DRAWINGS, vectors)
		if v != vectors:
			vectors = v
			rebuild = true
	if config.has("forward_force"):
		var ff: float = float(config["forward_force"])
		if not is_equal_approx(ff, forward_force):
			forward_force = ff
			rebuild = true
	if config.has("up_force"):
		var uf: float = float(config["up_force"])
		if not is_equal_approx(uf, up_force):
			up_force = uf
			rebuild = true
	if config.has("gravity_magnitude"):
		var gm: float = float(config["gravity_magnitude"])
		if not is_equal_approx(gm, gravity_magnitude):
			gravity_magnitude = gm
			rebuild = true
	if config.has("cooldown_time"):
		cooldown_time = float(config["cooldown_time"])
	if rebuild and _built and is_inside_tree():
		_rebuild()


## An unreadable word keeps the current value rather than silently blanking a pad
## eight rooms expect to be lit.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.strip_edges().to_lower()
	if allowed.has(v):
		return v
	if v != "":
		push_warning("force_pad: unknown value '%s' — keeping '%s'" % [v, fallback])
	return fallback


func _rebuild() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_accent_mats.clear()
	_pad_mat = null
	_arrow = null
	_arrow_up = null
	_arrow_g = null
	_foresight_mesh = null
	_built = false
	_ready()


# ── Build ───────────────────────────────────────────────────────────────

func _build_pad() -> void:
	# Recessed dark base ring (a 1x1 m footprint).
	var base := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = Vector3(1.0, 0.1, 1.0)
	base.mesh = bm; base.position.y = 0.05
	var base_mat := StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.08, 0.09, 0.12)
	base_mat.metallic = 0.7; base_mat.roughness = 0.4
	base.material_override = base_mat
	add_child(base)

	# Glowing top plate (slightly inset).
	var plate := MeshInstance3D.new()
	var pm := BoxMesh.new(); pm.size = Vector3(0.9, 0.06, 0.9)
	plate.mesh = pm; plate.position.y = 0.11
	_pad_mat = StandardMaterial3D.new()
	_pad_mat.albedo_color = pad_color.darkened(0.35)
	_pad_mat.emission_enabled = true
	_pad_mat.emission = pad_color
	_pad_mat.emission_energy_multiplier = 1.6
	plate.material_override = _pad_mat
	add_child(plate)
	_accent_mats.append(_pad_mat)

	# Neon edge frame.
	for off in [Vector3(0, 0, 0.46), Vector3(0, 0, -0.46), Vector3(0.46, 0, 0), Vector3(-0.46, 0, 0)]:
		var horiz: bool = absf(off.x) < 0.01
		var sz: Vector3 = Vector3(1.0, 0.09, 0.08) if horiz else Vector3(0.08, 0.09, 1.0)
		_emissive_box(sz, off + Vector3(0, 0.06, 0), pad_color.lightened(0.2), 2.4)

	# Three forward chevrons (flat cones pointing +Z) on the surface.
	for i in range(3):
		var chev := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0; cone.bottom_radius = 0.16; cone.height = 0.22; cone.radial_segments = 4
		chev.mesh = cone
		chev.rotation_degrees = Vector3(-90, 0, 0)   # point +Z, lying flat
		chev.position = Vector3(0, 0.15, -0.28 + i * 0.26)
		var cm := StandardMaterial3D.new()
		cm.albedo_color = pad_color
		cm.emission_enabled = true; cm.emission = pad_color
		cm.emission_energy_multiplier = 2.8 - i * 0.5
		cm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		chev.material_override = cm
		add_child(chev)
		_accent_mats.append(cm)


func _build_area() -> void:
	var area := Area3D.new()
	area.name = "LaunchZone"
	area.collision_layer = 0
	area.collision_mask = PLAYER_MASK
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new(); box.size = Vector3(1.0, 1.5, 1.0)
	col.shape = box
	col.position.y = 0.75
	area.add_child(col)
	add_child(area)
	area.body_entered.connect(_on_body_entered)


# ── Launch ──────────────────────────────────────────────────────────────

func _launch_velocity() -> Vector3:
	var fwd := global_transform.basis.z   # pad forward (+Z), rotates with placement
	fwd.y = 0.0
	if fwd.length() < 0.01:
		fwd = Vector3(0, 0, 1)
	return fwd.normalized() * forward_force + Vector3.UP * up_force


func _on_body_entered(body: Node3D) -> void:
	if _cooldown > 0.0:
		return
	if body.is_in_group("player_body") or body is CharacterBody3D:
		if "velocity" in body:
			body.set("velocity", _launch_velocity())
		_cooldown = cooldown_time
		_flash()


func _flash() -> void:
	for m in _accent_mats:
		m.emission_energy_multiplier = 6.0


# ── Indicator arrow (up + forward launch vector) ───────────────────────────

## vectors — how "what you give" is drawn at the pad. The default branch is the
## shipped pad exactly: ONE arrow, the same colour, nothing else.
func _build_arrow() -> void:
	match vectors:
		"components":
			# v0 = forward*f̂ + up*ŷ taken apart into the two things it is made of —
			# the pad's own @identity claim, drawn instead of asserted.
			_arrow = _make_arrow(pad_color.lightened(0.25))
			add_child(_arrow)
			_arrow_up = _make_arrow(pad_color.lightened(0.45))
			add_child(_arrow_up)
		"sum":
			# the throw AND the constant that will take it back.
			_arrow = _make_arrow(pad_color.lightened(0.25))
			add_child(_arrow)
			_arrow_g = _make_arrow(GRAVITY_COLOR)
			add_child(_arrow_g)
		"gravity":
			# only the given. A pad that shows you what is always acting on you and
			# says nothing about what it is about to add.
			_arrow_g = _make_arrow(GRAVITY_COLOR)
			add_child(_arrow_g)
		_:
			_arrow = _make_arrow(pad_color.lightened(0.25))
			add_child(_arrow)


func _refresh_arrow() -> void:
	if vectors == "components":
		if is_instance_valid(_arrow):
			var f: Vector3 = Vector3(0.0, 0.0, 1.0) * clampf(forward_force * 0.13, 0.4, 1.6)
			_position_arrow(_arrow, LAUNCH_ORIGIN, f)
		if is_instance_valid(_arrow_up):
			var u: Vector3 = Vector3.UP * clampf(up_force * 0.13, 0.4, 1.6)
			_position_arrow(_arrow_up, LAUNCH_ORIGIN, u)
	elif is_instance_valid(_arrow):
		var v := _launch_velocity()
		var dir := v.normalized() * clampf(v.length() * 0.13, 0.6, 1.6)
		# express in local space (so it ignores the node's own rotation correctly)
		var local_dir := global_transform.basis.inverse() * (dir)
		_position_arrow(_arrow, Vector3(0, 0.2, 0), local_dir)
	if is_instance_valid(_arrow_g):
		var g: Vector3 = Vector3.DOWN * clampf(gravity_magnitude * 0.055, 0.35, 0.95)
		_position_arrow(_arrow_g, LAUNCH_ORIGIN + Vector3(0.0, 0.72, 0.0), g)


# ── foresight: the arc, before you commit your feet ───────────────────────────

## The launch velocity in PAD-LOCAL space. The arrow uses the global basis because
## it has to survive an arbitrarily rotated placement; the drawn arc is a child of
## this node and rides that same rotation, so it is built local and left alone.
func _local_launch() -> Vector3:
	return Vector3(0.0, 0.0, 1.0) * forward_force + Vector3.UP * up_force


## Time from the launch point back down to floor level, from
## y0 + up*t - g/2*t^2 = 0.
func _flight_time() -> float:
	var g: float = maxf(gravity_magnitude, 0.001)
	var disc: float = up_force * up_force + 2.0 * g * LAUNCH_ORIGIN.y
	return (up_force + sqrt(maxf(disc, 0.0))) / g


func _build_foresight() -> void:
	if foresight == "none":
		return
	var mi := MeshInstance3D.new()
	mi.name = "Foresight"
	var im := ImmediateMesh.new()
	mi.mesh = im
	var mat := StandardMaterial3D.new()
	mat.albedo_color = pad_color.lightened(0.30)
	mat.emission_enabled = true
	mat.emission = pad_color.lightened(0.30)
	mat.emission_energy_multiplier = 2.4
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat
	add_child(mi)
	_accent_mats.append(mat)
	_foresight_mesh = im

	im.clear_surfaces()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	match foresight:
		"apex":
			_emit_apex()
		"landing":
			_emit_landing()
		_:
			_emit_arc()
	im.surface_end()


func _emit_seg(a: Vector3, b: Vector3) -> void:
	if _foresight_mesh == null:
		return
	_foresight_mesh.surface_add_vertex(a)
	_foresight_mesh.surface_add_vertex(b)


## foresight:parabola — the whole flight, dotted. Every other sample drawn, so the
## path reads as a prediction rather than as a rail.
func _emit_arc() -> void:
	var v0: Vector3 = _local_launch()
	var g: Vector3 = Vector3(0.0, -maxf(gravity_magnitude, 0.001), 0.0)
	var total: float = _flight_time()
	var steps: int = 48
	var prev: Vector3 = LAUNCH_ORIGIN
	for i in range(1, steps + 1):
		var t: float = total * float(i) / float(steps)
		var pos: Vector3 = LAUNCH_ORIGIN + v0 * t + 0.5 * g * t * t
		if i % 2 == 0:
			_emit_seg(prev, pos)
		prev = pos


## foresight:apex — the summit only. How HIGH, not where. A cross at the peak and
## a plumb line down so the height is readable against the floor.
func _emit_apex() -> void:
	var v0: Vector3 = _local_launch()
	var g: float = maxf(gravity_magnitude, 0.001)
	var t: float = maxf(up_force / g, 0.0)
	var apex: Vector3 = LAUNCH_ORIGIN + v0 * t + Vector3(0.0, -0.5 * g * t * t, 0.0)
	var s: float = 0.16
	_emit_seg(LAUNCH_ORIGIN, LAUNCH_ORIGIN + v0.normalized() * 0.30)
	_emit_seg(apex - Vector3(s, 0.0, 0.0), apex + Vector3(s, 0.0, 0.0))
	_emit_seg(apex - Vector3(0.0, s, 0.0), apex + Vector3(0.0, s, 0.0))
	_emit_seg(apex - Vector3(0.0, 0.0, s), apex + Vector3(0.0, 0.0, s))
	_emit_seg(apex, Vector3(apex.x, 0.0, apex.z))


## foresight:landing — the target only. A ring drawn on the floor where you come
## down, and no account at all of the flight in between.
func _emit_landing() -> void:
	var v0: Vector3 = _local_launch()
	var t: float = _flight_time()
	var hit: Vector3 = Vector3(v0.x * t, 0.02, v0.z * t)
	var r: float = 0.35
	var segs: int = 28
	var prev: Vector3 = hit + Vector3(r, 0.0, 0.0)
	for i in range(1, segs + 1):
		var a: float = TAU * float(i) / float(segs)
		var p: Vector3 = hit + Vector3(cos(a) * r, 0.0, sin(a) * r)
		_emit_seg(prev, p)
		prev = p
	_emit_seg(hit - Vector3(r * 0.45, 0.0, 0.0), hit + Vector3(r * 0.45, 0.0, 0.0))
	_emit_seg(hit - Vector3(0.0, 0.0, r * 0.45), hit + Vector3(0.0, 0.0, r * 0.45))


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
	_pulse_t += delta
	var pulse: float = 1.3 + 0.7 * (0.5 + 0.5 * sin(_pulse_t * 3.2))
	if _cooldown <= 0.0 and _pad_mat:
		_pad_mat.emission_energy_multiplier = pulse


# ── Helpers ────────────────────────────────────────────────────────────────

func _emissive_box(size: Vector3, pos: Vector3, color: Color, energy: float) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = size
	mi.mesh = bm; mi.position = pos
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true; m.emission = color; m.emission_energy_multiplier = energy
	mi.material_override = m
	add_child(mi)
	_accent_mats.append(m)


func _make_arrow(color: Color) -> Node3D:
	var root := Node3D.new()
	var shaft := MeshInstance3D.new()
	var sm := CylinderMesh.new(); sm.top_radius = 0.03; sm.bottom_radius = 0.03; sm.height = 1.0
	shaft.mesh = sm; shaft.name = "Shaft"
	var head := MeshInstance3D.new()
	var hm := CylinderMesh.new(); hm.top_radius = 0.0; hm.bottom_radius = 0.09; hm.height = 0.2
	head.mesh = hm; head.name = "Head"
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color; mat.emission_enabled = true; mat.emission = color
	mat.emission_energy_multiplier = 2.2; mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shaft.material_override = mat; head.material_override = mat
	root.add_child(shaft); root.add_child(head)
	_accent_mats.append(mat)
	return root


func _position_arrow(arrow: Node3D, origin: Vector3, vec: Vector3) -> void:
	if not is_instance_valid(arrow):
		return
	var length: float = vec.length()
	arrow.position = origin
	if length < 0.01:
		arrow.visible = false
		return
	arrow.visible = true
	var dir := vec.normalized()
	var up := Vector3.UP if absf(dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	var b := Basis.looking_at(dir, up)
	arrow.basis = Basis(b.x, dir, -b.z)
	var shaft: MeshInstance3D = arrow.get_node_or_null("Shaft")
	var head: MeshInstance3D = arrow.get_node_or_null("Head")
	if shaft:
		shaft.position = Vector3(0, length * 0.5, 0)
		shaft.scale = Vector3(1, length, 1)
	if head:
		head.position = Vector3(0, length, 0)
