# random_walk_leash.gd
# Random Walk Leash — hold a glowing orb on a string.
# The orb tugs in random directions, pulling against your grip.
# Feel the random walk through your VR hand.
#
# QFEP: Embodied randomness — the random walk isn't watched, it's felt.
# Your arm becomes the accumulator of stochastic impulses.
#
# @identity
# essence: F_tug = impulse_strength · random_unit_vector — stochastic forcing on a tethered body
# desire: grab the orb and feel randomness pulling your hand — your arm is the integral of noise
# critical_parameter: impulse_strength — the force per tug; too low and you feel nothing, too high and it escapes
# triggers: _impulse_timer fires every impulse_interval seconds, applying a random 3D impulse to the orb
# emerges: RMS displacement tracks sqrt(N) — the fundamental diffusion law felt through proprioception
# needs: XRToolsPickable grab [has], leash constraint [has], trail visualization [has]
# relationships: contrasts with random_walk_terrarium (observed vs embodied); depends on entropy_axiom conceptually
# truth: To hold randomness on a leash is to feel that unpredictability has weight.

extends Node3D

class_name RandomWalkLeash

# ── Orb ─────────────────────────────────────────────────────────────────────
@export var orb_radius: float = 0.05
@export var orb_mass: float = 0.15
@export var orb_color: Color = Color(0.3, 0.8, 1.0)
@export var orb_emission_energy: float = 1.5

# ── Leash ───────────────────────────────────────────────────────────────────
@export var leash_length: float = 0.4
@export var leash_segments: int = 8
@export var leash_color: Color = Color(0.6, 0.7, 0.9, 0.7)

# ── Random Walk ─────────────────────────────────────────────────────────────
@export var impulse_interval: float = 0.3   ## seconds between tugs
@export var impulse_strength: float = 0.04  ## force per tug
@export var walk_bias: float = 0.0          ## 0 = unbiased, >0 biases upward

# ── Pedestal / post ─────────────────────────────────────────────────────────
@export var pedestal_height: float = 0.9
## Post BOTTOM radius. The top is this minus POST_TAPER — the cabinet needs both
## by name so its cladding hugs the cylinder instead of guessing at it.
@export var pedestal_radius: float = 0.14
@export var pedestal_color: Color = Color(0.1, 0.1, 0.12)
const POST_TAPER: float = 0.02

# ── Cabinet — the TETHER POST (cabinet grammar, vertical dialect) ────────────
## One word drives every housing colour via HangarKit.finish_palette():
## "rams" (light Braun default) or "terminal" (dark console).
@export var finish: String = "terminal"
@export var wear: float = 0.10
@export var unit_code: String = "RW-10"

# ── Internal ────────────────────────────────────────────────────────────────
var _orb_body: RigidBody3D
var _orb_spawn_pos: Vector3
var _leash_line: MeshInstance3D
var _leash_material: StandardMaterial3D
var _impulse_timer: float = 0.0
var _total_tugs: int = 0
var _displacement_sum: Vector3 = Vector3.ZERO
var _is_held: bool = false

var _trail_points: Array[Vector3] = []
var _trail_mesh: MeshInstance3D
var _trail_material: StandardMaterial3D
const MAX_TRAIL: int = 200

# The service screen lives IN the cabinet's column (the 2026-07-20 interface
# ruling): the readout is destroyed and rebuilt on every change, so the ANCHOR
# is what stays put — the galton kiosk pattern.
var _stats_tag: Node3D                 # the current HangarKit.readout under the anchor
var _screen_anchor: Node3D             # stable mount point on the column face
var _screen_size: Vector2 = Vector2(0.24, 0.24)
var _stats_text: String = ""           # change guard — rebuild only on new numbers
var _tug_lamp: MeshInstance3D          # ember lamp on the gantry, pulsed per impulse
var _pad_pos: Vector3 = Vector3.ZERO   # where the keypad lands (set by _create_cabinet)

const BakedText = preload("res://commons/utils/baked_text_albedo.gd")
const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")
const PICKABLE_SCENE = preload("res://addons/godot-xr-tools/objects/pickable.tscn")
const HIGHLIGHT_RING_SCENE = preload("res://addons/godot-xr-tools/objects/highlight/highlight_ring.tscn")


# ═════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	# The anchor first: the cabinet's gantry EYE is built at exactly this point,
	# and the drawn leash now starts here too, so constraint / string / housing
	# are one place instead of three.
	_orb_spawn_pos = Vector3(0, pedestal_height + 0.15, 0)
	_pad_pos = Vector3(0, pedestal_height + 0.05, 0.15)   # legacy fallback
	_create_pedestal()
	_create_orb()
	_create_leash_visual()
	_create_trail()
	_create_labels()
	_create_cabinet()
	_create_vr_controls()


func _physics_process(delta: float) -> void:
	if not _orb_body:
		return

	# Apply random impulses
	_impulse_timer += delta
	if _impulse_timer >= impulse_interval:
		_impulse_timer = 0.0
		_apply_random_impulse()

	# Enforce leash constraint when held
	if _is_held:
		_enforce_leash()

	# Update visuals
	_update_leash_visual()
	_update_trail()
	_update_display()


# ═════════════════════════════════════════════════════════════════════════════
# PEDESTAL
# ═════════════════════════════════════════════════════════════════════════════

func _create_pedestal() -> void:
	var body := StaticBody3D.new()
	body.name = "Pedestal"

	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = pedestal_radius - POST_TAPER
	shape.height = pedestal_height
	col.shape = shape
	body.add_child(col)

	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = pedestal_radius - POST_TAPER
	cyl.bottom_radius = pedestal_radius
	cyl.height = pedestal_height
	cyl.radial_segments = 16
	mesh.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = pedestal_color
	mat.metallic = 0.3
	mat.roughness = 0.6
	mesh.material_override = mat
	body.add_child(mesh)

	body.position = Vector3(0, pedestal_height / 2.0, 0)
	add_child(body)

	# Rest cradle on top — family steel, not a bespoke blue-grey (G4 palette).
	var cradle := MeshInstance3D.new()
	cradle.name = "Cradle"
	var cradle_mesh := TorusMesh.new()
	cradle_mesh.inner_radius = orb_radius * 0.7
	cradle_mesh.outer_radius = orb_radius * 1.1
	cradle_mesh.rings = 16
	cradle_mesh.ring_segments = 12
	cradle.mesh = cradle_mesh
	var cradle_pal: Dictionary = HangarKit.finish_palette(finish)
	var cradle_col: Color = cradle_pal["panel"]
	cradle.material_override = HangarKit.worn_metal(cradle_col)
	cradle.position = Vector3(0, pedestal_height + 0.01, 0)
	cradle.rotation.x = PI / 2.0
	add_child(cradle)


# ═════════════════════════════════════════════════════════════════════════════
# ORB (VR grabbable)
# ═════════════════════════════════════════════════════════════════════════════

func _create_orb() -> void:
	var pickable: XRToolsPickable = PICKABLE_SCENE.instantiate() as XRToolsPickable
	if pickable == null:
		push_error("RandomWalkLeash: Failed to instantiate XRTools pickable.")
		return

	_orb_body = pickable
	_orb_body.name = "Orb"
	pickable.press_to_hold = true
	pickable.ranged_grab_method = XRToolsPickable.RangedMethod.NONE
	_orb_body.mass = orb_mass
	_orb_body.gravity_scale = 0.3  # Light feel — mostly driven by random impulses
	_orb_body.linear_damp = 1.5
	_orb_body.angular_damp = 2.0
	_orb_body.continuous_cd = true

	# Collision
	var col := _orb_body.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col == null:
		col = CollisionShape3D.new()
		_orb_body.add_child(col)
	var shape := SphereShape3D.new()
	shape.radius = orb_radius
	col.shape = shape

	# Glowing orb mesh
	var mesh := MeshInstance3D.new()
	mesh.name = "OrbMesh"
	var sphere := SphereMesh.new()
	sphere.radius = orb_radius
	sphere.height = orb_radius * 2.0
	sphere.radial_segments = 24
	sphere.rings = 12
	mesh.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = orb_color
	mat.emission_enabled = true
	mat.emission = orb_color
	mat.emission_energy_multiplier = orb_emission_energy
	mat.metallic = 0.2
	mat.roughness = 0.1
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.85
	mesh.material_override = mat
	_orb_body.add_child(mesh)

	# Inner glow core
	var core := MeshInstance3D.new()
	var core_sphere := SphereMesh.new()
	core_sphere.radius = orb_radius * 0.5
	core_sphere.height = orb_radius
	core.mesh = core_sphere
	var core_mat := StandardMaterial3D.new()
	core_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.6)
	core_mat.emission_enabled = true
	core_mat.emission = Color(0.8, 0.95, 1.0)
	core_mat.emission_energy_multiplier = 3.0
	core_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	core.material_override = core_mat
	_orb_body.add_child(core)

	# Highlight ring
	var highlight: Node3D = HIGHLIGHT_RING_SCENE.instantiate() as Node3D
	if highlight:
		highlight.position = Vector3(0, -orb_radius * 0.9, 0)
		highlight.scale = Vector3.ONE * (orb_radius / 0.03)
		_orb_body.add_child(highlight)

	_orb_body.position = Vector3(0, pedestal_height + 0.15, 0)

	if _orb_body.has_signal("dropped"):
		_orb_body.dropped.connect(_on_orb_dropped)
	if _orb_body.has_signal("picked_up"):
		_orb_body.picked_up.connect(_on_orb_picked_up)

	add_child(_orb_body)


func _on_orb_picked_up(_pickable) -> void:
	_is_held = true
	_trail_points.clear()


func _on_orb_dropped(_pickable) -> void:
	_is_held = false


# ═════════════════════════════════════════════════════════════════════════════
# RANDOM WALK
# ═════════════════════════════════════════════════════════════════════════════

func _apply_random_impulse() -> void:
	var direction := Vector3(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0) + walk_bias,
		randf_range(-1.0, 1.0)
	).normalized()

	_orb_body.apply_impulse(direction * impulse_strength)
	_displacement_sum += direction
	_total_tugs += 1

	# Pulse the orb color on each tug
	var orb_mesh := _orb_body.get_node_or_null("OrbMesh") as MeshInstance3D
	if orb_mesh and orb_mesh.material_override:
		var m: StandardMaterial3D = orb_mesh.material_override
		var pulse_color := Color(1.0, 1.0, 1.0)
		m.emission_energy_multiplier = orb_emission_energy * 2.5
		var tw := create_tween()
		tw.tween_property(m, "emission_energy_multiplier", orb_emission_energy, 0.2)

	# The retired DirectionTag's job, told in light: the gantry's tug lamp
	# flickers on every impulse, so the tug reads from the BODY, not a
	# billboard floating beside it.
	if _tug_lamp != null and is_instance_valid(_tug_lamp):
		var lm: StandardMaterial3D = _tug_lamp.material_override as StandardMaterial3D
		if lm != null:
			lm.emission_energy_multiplier = 4.5
			var tw2 := create_tween()
			tw2.tween_property(lm, "emission_energy_multiplier", 1.2, 0.2)


func _enforce_leash() -> void:
	# Keep orb within leash_length of its grab point
	# The pickable system handles the grip — we just add a soft constraint
	# by damping velocity when the orb moves far from its rest position
	var dist := _orb_body.global_position.distance_to(global_position + _orb_spawn_pos)
	if dist > leash_length:
		var pull_dir := (global_position + _orb_spawn_pos - _orb_body.global_position).normalized()
		_orb_body.apply_force(pull_dir * (dist - leash_length) * 2.0)


# ═════════════════════════════════════════════════════════════════════════════
# LEASH VISUAL (line from orb to pedestal top)
# ═════════════════════════════════════════════════════════════════════════════

func _create_leash_visual() -> void:
	_leash_line = MeshInstance3D.new()
	_leash_line.name = "LeashLine"
	_leash_material = StandardMaterial3D.new()
	_leash_material.albedo_color = leash_color
	_leash_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_leash_material.emission_enabled = true
	_leash_material.emission = Color(0.4, 0.5, 0.8)
	_leash_material.emission_energy_multiplier = 0.3
	_leash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	add_child(_leash_line)


func _update_leash_visual() -> void:
	if not _orb_body or not _leash_line:
		return

	# The GANTRY EYE. _enforce_leash() already pulls toward _orb_spawn_pos; the
	# string used to be drawn from a different, bodiless point on the post top.
	# One point now — constraint, drawing and the ring on the arm agree.
	var start := _orb_spawn_pos
	var end := _orb_body.global_position - global_position

	# Simple cylinder between two points
	var dir := end - start
	var length := dir.length()
	if length < 0.001:
		return

	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	im.surface_add_vertex(start)
	im.surface_add_vertex(end)
	im.surface_end()
	_leash_line.mesh = im
	_leash_line.material_override = _leash_material


# ═════════════════════════════════════════════════════════════════════════════
# TRAIL
# ═════════════════════════════════════════════════════════════════════════════

func _create_trail() -> void:
	_trail_mesh = MeshInstance3D.new()
	_trail_mesh.name = "Trail"
	_trail_material = StandardMaterial3D.new()
	_trail_material.albedo_color = Color(0.3, 0.6, 1.0, 0.3)
	_trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_trail_material.emission_enabled = true
	_trail_material.emission = orb_color * 0.5
	_trail_material.emission_energy_multiplier = 0.3
	_trail_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	add_child(_trail_mesh)


func _update_trail() -> void:
	if not _orb_body or not _trail_mesh:
		return

	var orb_local := _orb_body.global_position - global_position
	_trail_points.append(orb_local)
	if _trail_points.size() > MAX_TRAIL:
		_trail_points.pop_front()

	if _trail_points.size() < 2:
		return

	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for pt in _trail_points:
		im.surface_add_vertex(pt)
	im.surface_end()
	_trail_mesh.mesh = im
	_trail_mesh.material_override = _trail_material


# ═════════════════════════════════════════════════════════════════════════════
# LABELS
# ═════════════════════════════════════════════════════════════════════════════

## RETIRED: the title and subtitle used to be billboards floating at
## (0, ph+0.35, -0.15) and (0, ph+0.29, -0.15) — INSIDE the orb's roam sphere,
## swivelling to the camera across the phenomenon. The cabinet's sign band owns
## the name now, and the live numbers moved into the column's screen. All this
## function still does is arm the change guard.
func _create_labels() -> void:
	_stats_text = ""


## What the screen says before the first tug.
func _idle_lines() -> Array:
	return ["N       0", "", "GRAB THE ORB", "LAW  RMS ~ SQRT N"]


## The service screen — the old floating StatsTag, re-homed into the column.
## The kit's framed readout is destroyed and rebuilt on change, so the anchor
## node is the thing that stays put (the galton kiosk pattern).
func _refresh_screen(lines: Array) -> void:
	if _screen_anchor == null or not is_instance_valid(_screen_anchor):
		return
	if _stats_tag != null and is_instance_valid(_stats_tag):
		_stats_tag.queue_free()
	_stats_tag = null
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var scr: Node3D = HangarKit.readout("WALK", lines, _screen_size,
		pal["screen"], pal["text"], pal["header"], finish)
	if scr != null:
		scr.position = Vector3.ZERO
		_screen_anchor.add_child(scr)
		_stats_tag = scr


func _update_display() -> void:
	if _total_tugs == 0:
		return

	# RMS displacement
	var rms: float = _displacement_sum.length() / sqrt(float(_total_tugs))
	var drift: float = _displacement_sum.length()

	# Change guard: the screen is a rebuilt node, so it must only rebuild when
	# the numbers actually move (a tug), never once per physics frame.
	var sig: String = "%d|%.2f|%.2f" % [_total_tugs, drift, rms]
	if sig == _stats_text:
		return
	_stats_text = sig
	_refresh_screen([
		"N       %d" % _total_tugs,
		"DRIFT   %.2f" % drift,
		"RMS     %.2f" % rms,
		"LAW  RMS ~ SQRT N",
	])


# ═════════════════════════════════════════════════════════════════════════════
# THE CABINET — the TETHER POST (vertical dialect, unit RW-10)
# ═════════════════════════════════════════════════════════════════════════════
## The interface is part of the body (cabinet grammar, 2026-07-20). The plane
## picks the dialect first: the phenomenon here is a glowing orb roaming a
## sphere of FREE AIR at chest height, trailing a line drawn through the volume.
## There is no deck to look down at — you stand, you face it, you reach out.
## VERTICAL, unambiguously.
##
## But every vertical body that already exists would foul this phenomenon. The
## specimen dock is the right ANCESTOR (a pickable that lifts out of a cradle)
## and the wrong BODY — its three struts would stand permanently inside the
## roam volume and the trail would be read through bars. A pedestal station's
## backboard slab would sit inside the sphere and flatten the walk into
## scribble on a wall. So the body is new: the vending machine's SERVICE COLUMN
## detached from its window.
##
##   post        the re-clad pedestal, carrying the cradle
##   column      beside it — readout, keypad, vents, unit code, sign band
##   gantry      an arm off the column top reaching over the post's axis to the
##               TETHER EYE: the one point where the leash constraint, the
##               drawn string and the housing finally agree
##   base plate  one foot under both, so this is ONE machine and not a post
##               standing next to a kiosk
##
## No plinth: the keypad already sits at 0.95 m, inside the 0.75–1.35 reach
## band, so G5 is satisfied by the artifact's own geometry. A pedestal here
## would be a fix for a problem it does not have.
func _create_cabinet() -> void:
	var ph: float = pedestal_height
	var pr: float = pedestal_radius
	var ar: float = _orb_spawn_pos.y                   # the anchor — physics' own point
	var cw: float = 0.30                               # column width (hosts the 0.172 rack panel)
	var cd: float = 0.24
	var colx: float = pr + 0.06 + cw / 2.0             # inner face clears the post by 0.06
	var inner: float = colx - cw / 2.0                 # the gantry's reach
	var facez: float = cd / 2.0
	var top: float = ar + leash_length                 # rises exactly to the leash sphere's crown
	var cap_h: float = 0.10

	var cab := Node3D.new()
	cab.name = "Cabinet"
	cab.set_meta("housing", true)                      # scope the grammar probe's rules here
	add_child(cab)

	# ── One palette word drives every part (the kit's finish system) ──────
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var col_body: Color = pal["body"]
	var col_panel: Color = pal["panel"]
	var col_accent: Color = pal["accent"]
	var ew: float = float(pal["wear"]) if finish.to_lower() == "terminal" else wear

	var shell: StandardMaterial3D = HangarKit.finish_body(finish, col_body, ew)
	var dark: StandardMaterial3D = HangarKit.painted_metal(Color(0.09, 0.09, 0.105), ew, 0.4, 0.5)
	var maroon: StandardMaterial3D = HangarKit.painted_metal(Color(0.30, 0.11, 0.09), ew)
	var steel: StandardMaterial3D = HangarKit.worn_metal(col_panel)
	var accent: StandardMaterial3D = HangarKit.emissive(col_accent, 2.2)

	# ── Shared base plate: the move that makes post + column ONE machine ──
	var right_edge: float = colx + cw / 2.0 + 0.05
	var left_edge: float = -(pr + 0.05)
	var bw: float = right_edge - left_edge
	var bx: float = (right_edge + left_edge) / 2.0
	cab.add_child(HangarKit.box(Vector3(bx, 0.045, 0.0),
		Vector3(bw, 0.09, cd + 0.06), dark))
	var feet_x: Array[float] = [bx - bw / 2.0 + 0.09, bx + bw / 2.0 - 0.09]
	for fi in range(feet_x.size()):
		cab.add_child(HangarKit.box(Vector3(feet_x[fi], 0.012, 0.0),
			Vector3(0.11, 0.024, cd + 0.02), dark))

	# ── Re-clad the POST: a round body takes its age from BANDING ─────────
	# (kit gotcha: grime_band is a FLAT plate — on a cylinder it juts off as a
	#  slab. Round bodies get a light mid-section between dark collars instead.)
	var band_lo: float = ph * 0.21
	var band_hi: float = ph * 0.83
	var band := MeshInstance3D.new()
	band.name = "PostBand"
	var band_mesh := CylinderMesh.new()
	band_mesh.bottom_radius = pr - POST_TAPER * (band_lo / ph) + 0.002
	band_mesh.top_radius = pr - POST_TAPER * (band_hi / ph) + 0.002
	band_mesh.height = band_hi - band_lo
	band_mesh.radial_segments = 32
	band.mesh = band_mesh
	band.material_override = shell
	band.position = Vector3(0.0, (band_lo + band_hi) / 2.0, 0.0)
	cab.add_child(band)

	var collar_y: Array[float] = [ph * 0.285, ph * 0.715]
	for ci in range(collar_y.size()):
		var cy: float = collar_y[ci]
		var collar := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = pr - POST_TAPER * (cy / ph) + 0.008
		cm.bottom_radius = cm.top_radius
		cm.height = 0.022
		cm.radial_segments = 32
		collar.mesh = cm
		collar.material_override = dark
		collar.position = Vector3(0.0, cy, 0.0)
		cab.add_child(collar)

	var post_bolt_r: float = pr - POST_TAPER * 0.5 + 0.004
	for bi in range(4):
		var ang: float = TAU * float(bi) / 4.0 + 0.4
		var bxp: float = cos(ang) * post_bolt_r
		var bzp: float = sin(ang) * post_bolt_r
		cab.add_child(HangarKit.bolts(
			Vector3(bxp, ph * 0.33, bzp), Vector3(bxp, ph * 0.67, bzp),
			4, 0.008, steel))

	# ── SERVICE COLUMN, standing BESIDE the phenomenon, never behind it ────
	cab.add_child(HangarKit.box(Vector3(colx, top / 2.0, 0.0),
		Vector3(cw, top, cd), shell))
	# maroon flank on the OUTER side, full height (the vertical dialect's mass)
	cab.add_child(HangarKit.box(Vector3(colx + cw / 2.0 + 0.025, top / 2.0, 0.0),
		Vector3(0.05, top, cd + 0.03), maroon))
	# bolt rows down the front edges, below the keypad shoulder
	var edge_x: Array[float] = [colx - (cw / 2.0 - 0.018), colx + (cw / 2.0 - 0.018)]
	for ei in range(edge_x.size()):
		cab.add_child(HangarKit.bolts(
			Vector3(edge_x[ei], 0.22, facez + 0.002),
			Vector3(edge_x[ei], 0.82, facez + 0.002),
			7, 0.009, steel))

	# ── READOUT INSET — this is where the floating StatsTag moved to ──────
	var scr_w: float = cw - 0.06
	var scr_h: float = 0.24
	var scr_y: float = ph + 0.30
	cab.add_child(HangarKit.box(Vector3(colx, scr_y, facez - 0.008),
		Vector3(scr_w + 0.030, scr_h + 0.030, 0.030), dark))
	var anchor := Node3D.new()
	anchor.name = "WalkScreen"
	anchor.position = Vector3(colx, scr_y, facez + 0.006)
	cab.add_child(anchor)
	_screen_anchor = anchor
	_screen_size = Vector2(scr_w, scr_h)
	_stats_text = ""
	_refresh_screen(_idle_lines())
	# ember lip above the screen, then the Rams triad
	cab.add_child(HangarKit.box(Vector3(colx, scr_y + scr_h / 2.0 + 0.026, facez + 0.006),
		Vector3(scr_w + 0.030, 0.006, 0.004), accent))
	var bar: Node3D = HangarKit.three_color_bar(cw - 0.06, 0.016)
	if bar != null:
		bar.position = Vector3(colx, scr_y + scr_h / 2.0 + 0.048, facez + 0.006)
		cab.add_child(bar)

	# ── Service face: age at the foot, vent slats, the unit number ────────
	var gb: MeshInstance3D = HangarKit.grime_band(cw * 0.9, 0.055, facez + 0.004, col_body)
	if gb != null:
		gb.position.x = colx                 # keep the kit's baked z
		gb.position.y = 0.09 + 0.0275        # sitting on the base plate, where dirt collects
		cab.add_child(gb)
	for si in range(6):
		cab.add_child(HangarKit.box(
			Vector3(colx, 0.175 + float(si) * 0.024, facez + 0.002),
			Vector3(cw - 0.08, 0.010, 0.012), dark))
	var code: MeshInstance3D = HangarKit.stencil(unit_code, Vector2(0.12, 0.030),
		col_accent.lightened(0.25))
	if code != null:
		code.position = Vector3(colx, 0.35, facez + 0.004)
		cab.add_child(code)

	# ── Keypad shoulder: a WEDGE, so the pad meets the body ───────────────
	var wedge_y: float = ph + 0.05
	var wedge_h: float = 0.20
	var wedge_db: float = 0.105
	var wedge_dt: float = 0.012          # (db - dt) / h = 25 deg — the pad's own tilt
	var wedge_z: float = facez - 0.010
	var shoulder: MeshInstance3D = HangarKit.wedge(cw - 0.03, wedge_h, wedge_db, wedge_dt, dark)
	shoulder.name = "KeypadShoulder"
	shoulder.position = Vector3(colx, wedge_y, wedge_z)
	cab.add_child(shoulder)
	# where _create_vr_controls() lands the rack panel: ON the slope
	var pad_y: float = ph + 0.075
	var pad_t: float = clampf((pad_y - (wedge_y - wedge_h / 2.0)) / wedge_h, 0.0, 1.0)
	_pad_pos = Vector3(colx, pad_y, wedge_z + lerpf(wedge_db, wedge_dt, pad_t) + 0.008)

	# ── THE GANTRY — the part that makes this body its own ────────────────
	# One arm overhead; everything below stays open, so the walk is read
	# through air instead of through a cage.
	var eye_in: float = orb_radius * 1.5
	var eye_out: float = orb_radius * 1.9
	cab.add_child(HangarKit.box(
		Vector3((eye_in + inner) / 2.0, ar, 0.0),
		Vector3(inner - eye_in, 0.045, 0.055), shell))
	# haunch, so the arm is not cantilevered out of nothing
	cab.add_child(HangarKit.box(Vector3(inner - 0.045, ar - 0.050, 0.0),
		Vector3(0.09, 0.055, 0.045), shell))
	# THE EYE. TorusMesh already lies in XZ (hole axis up), so the orb spawns
	# inside the ring and drops through it to the cradle, leaving 0.10 m of
	# visible leash. Do NOT rotate it — that stands the ring up and seals it.
	var eye := MeshInstance3D.new()
	eye.name = "TetherEye"
	var eye_mesh := TorusMesh.new()
	eye_mesh.inner_radius = eye_in
	eye_mesh.outer_radius = eye_out
	eye_mesh.rings = 16
	eye_mesh.ring_segments = 12
	eye.mesh = eye_mesh
	eye.material_override = steel
	eye.position = Vector3(0.0, ar, 0.0)
	cab.add_child(eye)
	# tug lamp — the retired DirectionTag's job, told in light
	var lamp: MeshInstance3D = HangarKit.box(
		Vector3(inner - 0.03, ar + 0.026, 0.0), Vector3(0.036, 0.007, 0.007),
		HangarKit.emissive(col_accent, 1.2))
	lamp.name = "TugLamp"
	cab.add_child(lamp)
	_tug_lamp = lamp

	# ── Cap: sign band over a full-width ember line ───────────────────────
	var cap_w: float = cw + 0.16
	cab.add_child(HangarKit.box(Vector3(colx, top + cap_h / 2.0, 0.0),
		Vector3(cap_w, cap_h, cd + 0.06), shell))
	cab.add_child(HangarKit.box(Vector3(colx, top + 0.005, facez + 0.032),
		Vector3(cap_w, 0.007, 0.004), accent))
	cab.add_child(HangarKit.box(Vector3(colx, top + cap_h / 2.0, facez + 0.030),
		Vector3(cap_w - 0.02, 0.066, 0.012), dark))
	var sign_title: Node3D = BakedText.make_tag(
		"RANDOM WALK LEASH", Color(0.93, 0.94, 0.97), 0.026,
		Color(0.07, 0.075, 0.09), false, Color(0, 0, 0, 0))
	if sign_title != null:
		sign_title.name = "TitleTag"
		sign_title.position = Vector3(colx, top + cap_h / 2.0 + 0.013, facez + 0.038)
		cab.add_child(sign_title)
	var sign_sub: Node3D = BakedText.make_tag(
		"DIFFUSION  RMS ~ SQRT N", Color(0.55, 0.58, 0.66), 0.014,
		Color(0.07, 0.075, 0.09), false, Color(0, 0, 0, 0))
	if sign_sub != null:
		sign_sub.name = "SubTag"
		sign_sub.position = Vector3(colx, top + cap_h / 2.0 - 0.020, facez + 0.038)
		cab.add_child(sign_sub)


# ═════════════════════════════════════════════════════════════════════════════
# VR CONTROLS
# ═════════════════════════════════════════════════════════════════════════════

func _create_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("RANDOM WALK", [
		[{"type": "slider_h", "label": "IMPULSE", "default": impulse_strength / 0.1}],
		[{"type": "button", "label": "RESET"}],
	])
	# On the cabinet's WEDGE shoulder. It used to hang unsupported at
	# (0, ph+0.05, 0.15) — buttons in the air, in the front hemisphere of the
	# orb's roam sphere. Same height (so the reach band still reads), same -25
	# degree tilt (the wedge slope was cut to match it), now with a body under it.
	panel.position = _pad_pos
	panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(panel)

	# IMPULSE slider (Param_0)
	var imp_slider: Node = panel.find_child("Param_0", true, false)
	if imp_slider and imp_slider.has_signal("slider_moved"):
		imp_slider.slider_moved.connect(func(val: float):
			impulse_strength = imp_slider.get_normalized_value() * 0.1
		)

	# RESET button (Btn_0)
	var reset_btn: Node = panel.find_child("Btn_0", true, false)
	if reset_btn:
		var area = reset_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _reset())


func _reset() -> void:
	if _orb_body:
		_orb_body.freeze = true
		_orb_body.linear_velocity = Vector3.ZERO
		_orb_body.angular_velocity = Vector3.ZERO
		_orb_body.global_position = global_position + _orb_spawn_pos
		_orb_body.set_deferred("freeze", false)

	_total_tugs = 0
	_displacement_sum = Vector3.ZERO
	_impulse_timer = 0.0
	_trail_points.clear()
	_is_held = false
	_stats_text = ""
	_refresh_screen(_idle_lines())


func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
