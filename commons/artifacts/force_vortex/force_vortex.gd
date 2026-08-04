extends Node3D
class_name ForceVortex

# @identity
# essence: a rotating force field — a whirlpool that drags you toward its core,
#          spins you around it, then flings you back out. Force as a place.
# desire: to make a vector field bodily — not an arrow you read but a current you
#         are caught in: inward pull + tangential spin = a spiral you ride.
# critical_parameter: pull_strength + spin_strength set the spiral; eject_force +
#         eject_up set the throw. v_in = -r̂*pull + (ŷ×r)*spin; v_out = r̂*eject + ŷ*up.
# triggers: an Area3D on the player_body layer captures the player; each physics
#           frame the field overwrites their velocity with the spiral; crossing the
#           core radius ejects them (the proven XRToolsPlayerBody.velocity path).
# emerges: centripetal vs centrifugal felt in the gut — the field owns you, then
#          releases you faster than you came in.
# truth: a force field is a velocity assigned to every point in space.

const PLAYER_MASK := 524288

@export var field_radius: float = 3.5
@export var pull_strength: float = 4.5      # inward m/s
@export var spin_strength: float = 6.5      # tangential m/s
@export var lift: float = 1.4               # gentle upward while captured
@export var eject_radius: float = 0.9       # cross this → thrown out
@export var eject_force: float = 13.0       # outward m/s
@export var eject_up: float = 8.0           # upward m/s
@export var cooldown_time: float = 1.6
@export var field_color: Color = Color(0.65, 0.35, 1.0)   # violet
@export var core_color: Color = Color(1.0, 0.5, 0.9)

## AXIS — DEPICTION: what a force field is DRAWN AS. The law is not on this axis and never
## moves: every value applies the identical v_in = -r̂*pull + (ŷ×r)*spin + ŷ*lift and the
## identical throw at eject_radius, because the whole claim of this artifact is that the
## field is already there whether or not you can see it. What the axis decides is the only
## thing a body outside the ring has to go on — the shape the same 40-odd beads are laid
## in, and therefore what kind of object you take a field to BE.
##
##   spiral   THE LEGACY BODY, arithmetic for arithmetic: three logarithmic arms of 14
##            beads, 1.1 turns, rising 0.15 -> 1.35 as they go out. A field as a CURRENT —
##            you can see the path you will be carried along before you are on it
##   spokes   six straight rays lying flat on the floor, no twist at all. A field as a set
##            of ARROWS: the inward pull drawn honestly and the swirl not drawn, which is
##            the textbook picture and is missing half of what this thing does to you
##   rings    four concentric circles at one height, no radial direction anywhere. A field
##            as LEVEL SETS — where you are, never which way you are going
##   funnel   eight short arms on a squared rise, a steep wall climbing to 2.3. The
##            rubber-sheet WELL: a field as a landscape you fall down, gravity's own
##            metaphor imported into a vortex that has no mass in it
##   column   twelve posts standing the full height on the boundary itself. A field as a
##            ROOM you are inside, all edge and no interior — the thing you can only read
##            from the doorway
##
## GEOMETRY ONLY, and deliberately: the Area3D, the cylinder that captures you, the pull,
## the spin, the lift and the throw are byte-identical across all five values. A field you
## cannot see is not a weaker field.
const DEPICTIONS: PackedStringArray = ["spiral", "spokes", "rings", "funnel", "column"]
@export_enum("spiral", "spokes", "rings", "funnel", "column") var depiction: String = "spiral"

## AXIS — WARNING: how much the vortex tells you BEFORE it costs you anything. Adopted word
## for word, and value for value, from [[path_block]] — which took it from [[catalyst_vent]]
## — because it is the same question asked of the same kind of object. eject_radius is 0.9 m
## and NOTHING in the shipped drawing marks it: the core column is 0.22 m of glowing
## cylinder, the ring on the floor is the outer boundary, and the circle where the field
## stops pulling and starts throwing you is invisible. That is a legible fact about this
## artifact rather than an oversight, so it is the default.
##
##   none     the field alone, unannounced: ring, core and arms, and nothing at the throw
##            radius. THE LEGACY BODY, byte for byte — what all 5 placements render today
##   stain    a discolouration soaked into the floor out to the throw radius and nothing
##            above it. The warning exists but it is addressed to your feet
##   cage     eight bolted bars and a hoop standing on the radius. Someone measured it,
##            fenced it — and it throws you through the bars on exactly the same rule
##   beacon   a lit mast over the core and a glowing outline at the foot: the verdict
##            broadcast as light, readable across a dark room before you commit to walking
##   shroud   a canvas drape over the core. You cannot tell where the throw begins until
##            you are inside it. The quietest mark and the loudest claim
##
## APPEARANCE ONLY. eject_radius, eject_force and eject_up are untouched at every value;
## none of this geometry collides with anything.
const WARNINGS: PackedStringArray = ["none", "stain", "cage", "beacon", "shroud"]
@export_enum("none", "stain", "cage", "beacon", "shroud") var warning: String = "none"

const CONFIG_NUMERIC: PackedStringArray = ["field_radius", "pull_strength", "spin_strength",
		"lift", "eject_radius", "eject_force", "eject_up", "cooldown_time"]

enum S { IDLE, CAPTURED, COOLDOWN }

var _spinner: Node3D
var _core_mat: StandardMaterial3D
var _accent_mats: Array[StandardMaterial3D] = []
var _state: int = S.IDLE
var _player: Node3D = null
var _cooldown: float = 0.0
var _spin_phase: float = 0.0
var _built: bool = false


func _ready() -> void:
	depiction = _valid(depiction, DEPICTIONS, "spiral")
	warning = _valid(warning, WARNINGS, "none")
	_build_all()


## GUARDED, and it was not before. This used to free every child and re-enter _ready() on
## ANY call, so a placement that passed no key at all — or the same key twice — still tore
## the vortex down and rebuilt it. Now a value has to actually change, and the first build
## has to have happened, before anything is freed.
func apply_grid_config(config: Dictionary) -> void:
	var dirty: bool = false
	for k in CONFIG_NUMERIC:
		if config.has(k):
			var v: float = float(config[k])
			if not is_equal_approx(v, float(get(k))):
				set(k, v)
				dirty = true
	if config.has("depiction"):
		var d: String = _valid(str(config["depiction"]), DEPICTIONS, depiction)
		if d != depiction:
			depiction = d
			dirty = true
	if config.has("warning"):
		var w: String = _valid(str(config["warning"]), WARNINGS, warning)
		if w != warning:
			warning = w
			dirty = true
	if dirty and _built:
		_rebuild()


## A word the code cannot build falls back to what is already set, so a typo renders the
## shipped vortex rather than a blank floor.
func _valid(value: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = value.strip_edges().to_lower()
	return v if allowed.has(v) else fallback


func _rebuild() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_spinner = null
	_core_mat = null
	_accent_mats.clear()
	_player = null
	_state = S.IDLE
	_cooldown = 0.0
	_build_all()


func _build_all() -> void:
	_build_field()
	_build_area()
	_build_warning()
	_built = true


# ── Build ───────────────────────────────────────────────────────────────

func _build_field() -> void:
	# Ground ring marking the field boundary.
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = field_radius - 0.08
	torus.outer_radius = field_radius
	torus.rings = 48; torus.ring_segments = 8
	ring.mesh = torus
	ring.position.y = 0.04
	ring.material_override = _emissive(field_color, 2.0)
	add_child(ring)

	# Spinner holds the rotating arms + core (rotated in _physics_process).
	_spinner = Node3D.new()
	_spinner.name = "Spinner"
	add_child(_spinner)

	# Central glowing core column.
	var core := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.12; cyl.bottom_radius = 0.22; cyl.height = 3.0
	core.mesh = cyl; core.position.y = 1.5
	_core_mat = _emissive(core_color, 3.0)
	core.material_override = _core_mat
	_spinner.add_child(core)

	_build_depiction()


# ── DEPICTION ────────────────────────────────────────────────────────────
# One bead, one ramp. Every value below lays the SAME bead — same size taper, same
# field_color -> core_color gradient, same emission falloff — in a different arrangement,
# so what the sweep photographs is the shape and nothing else.

func _bead(rad: float, ang: float, y: float, t: float) -> void:
	var bead := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = lerpf(0.12, 0.04, t); sm.height = sm.radius * 2.0
	bead.mesh = sm
	bead.position = Vector3(cos(ang) * rad, y, sin(ang) * rad)
	var col := field_color.lerp(core_color, t)
	bead.material_override = _emissive(col, lerpf(3.2, 1.4, t))
	_spinner.add_child(bead)


func _build_depiction() -> void:
	match depiction:
		"spokes":
			_bank(6, 7, 0.0, 0.0, 0.15, 1.0)
		"funnel":
			_bank(8, 10, 0.35, 2.3, 0.12, 2.0)
		"rings":
			_rings(4, 12)
		"column":
			_posts(12, 5)
		_:
			# THE SHIPPED SPIRAL, arithmetic for arithmetic: three arms, 14 beads,
			# 1.1 turns, height 0.15 + t*1.2. Only the bead construction moved.
			var arms := 3
			var beads := 14
			for a in range(arms):
				var base := float(a) / float(arms) * TAU
				for i in range(beads):
					var t := float(i) / float(beads - 1)
					var rad := lerpf(0.25, field_radius * 0.98, t)
					var ang := base + t * TAU * 1.1          # 1.1 turns of spiral
					_bead(rad, ang, 0.15 + t * 1.2, t)


## Radiating arms. `turns` is how far round an arm walks between the core and the rim (0 is
## a straight ray), `bow` shapes the climb — 1.0 is the spiral's even rise, 2.0 the funnel's
## flat floor and steep wall.
func _bank(arms: int, beads: int, turns: float, rise: float, y0: float, bow: float) -> void:
	for a in range(arms):
		var base: float = float(a) / float(arms) * TAU
		for i in range(beads):
			var t: float = float(i) / float(maxi(beads - 1, 1))
			var rad: float = lerpf(0.25, field_radius * 0.98, t)
			_bead(rad, base + t * TAU * turns, y0 + rise * pow(t, bow), t)


## Level sets: closed circles at one height, so no bead points anywhere.
func _rings(count: int, per: int) -> void:
	for r in range(count):
		var t: float = float(r) / float(maxi(count - 1, 1))
		var rad: float = lerpf(0.25, field_radius * 0.98, t)
		for i in range(per):
			_bead(rad, float(i) / float(per) * TAU, 0.15, t)


## The boundary as a standing wall — all the beads on the rim, none inside.
func _posts(count: int, high: int) -> void:
	for p in range(count):
		var ang: float = float(p) / float(count) * TAU
		for j in range(high):
			var t: float = float(j) / float(maxi(high - 1, 1))
			_bead(field_radius * 0.94, ang, 0.2 + t * 2.4, t)


func _build_area() -> void:
	var area := Area3D.new()
	area.name = "VortexZone"
	area.collision_layer = 0
	area.collision_mask = PLAYER_MASK
	var col := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = field_radius
	cyl.height = 4.0
	col.shape = cyl
	col.position.y = 2.0
	area.add_child(col)
	add_child(area)
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)


# ── WARNING ──────────────────────────────────────────────────────────────
# Everything here stands on eject_radius, the circle where the field stops pulling and
# starts throwing. It is parented to the root, not to the Spinner: the threshold does not
# turn with the arms, it is a fact about the floor.

func _build_warning() -> void:
	if warning == "none" or not WARNINGS.has(warning):
		return                       # the shipped vortex marks nothing at all
	var er: float = maxf(eject_radius, 0.15)
	var host := Node3D.new()
	host.name = "Warning"
	add_child(host)
	match warning:
		"stain":
			var disc := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = er; cm.bottom_radius = er; cm.height = 0.012
			disc.mesh = cm
			disc.position.y = 0.02
			disc.material_override = _dull(Color(0.30, 0.10, 0.06, 0.85))
			host.add_child(disc)
		"cage":
			var bars := 8
			for b in range(bars):
				var ang: float = float(b) / float(bars) * TAU
				var bar := MeshInstance3D.new()
				var bm := BoxMesh.new()
				bm.size = Vector3(0.055, 2.2, 0.055)
				bar.mesh = bm
				bar.position = Vector3(cos(ang) * er, 1.1, sin(ang) * er)
				bar.material_override = _emissive(Color(0.86, 0.74, 0.18), 0.9)
				host.add_child(bar)
			var hoop := MeshInstance3D.new()
			var tm := TorusMesh.new()
			tm.inner_radius = er - 0.05; tm.outer_radius = er + 0.05
			tm.rings = 32; tm.ring_segments = 6
			hoop.mesh = tm
			hoop.position.y = 2.2
			hoop.material_override = _emissive(Color(0.86, 0.74, 0.18), 0.9)
			host.add_child(hoop)
		"beacon":
			var mast := MeshInstance3D.new()
			var mc := CylinderMesh.new()
			mc.top_radius = 0.05; mc.bottom_radius = 0.05; mc.height = 1.4
			mast.mesh = mc
			mast.position.y = 3.7
			mast.material_override = _emissive(Color(1.0, 0.85, 0.25), 5.0)
			host.add_child(mast)
			var lamp := MeshInstance3D.new()
			var ls := SphereMesh.new()
			ls.radius = 0.20; ls.height = 0.40
			lamp.mesh = ls
			lamp.position.y = 4.45
			lamp.material_override = _emissive(Color(1.0, 0.95, 0.6), 7.0)
			host.add_child(lamp)
			var outline := MeshInstance3D.new()
			var ot := TorusMesh.new()
			ot.inner_radius = er - 0.06; ot.outer_radius = er + 0.06
			ot.rings = 40; ot.ring_segments = 6
			outline.mesh = ot
			outline.position.y = 0.06
			outline.material_override = _emissive(Color(1.0, 0.85, 0.25), 4.5)
			host.add_child(outline)
		"shroud":
			var drape := MeshInstance3D.new()
			var dc := CylinderMesh.new()
			dc.top_radius = er * 0.85; dc.bottom_radius = er * 1.35; dc.height = 2.7
			drape.mesh = dc
			drape.position.y = 1.35
			drape.material_override = _dull(Color(0.62, 0.58, 0.50, 0.72))
			host.add_child(drape)
			var cap := MeshInstance3D.new()
			var cs := SphereMesh.new()
			cs.radius = er * 0.85; cs.height = er * 0.85
			cap.mesh = cs
			cap.position.y = 2.7
			cap.material_override = _dull(Color(0.66, 0.62, 0.54, 0.80))
			host.add_child(cap)
		_:
			pass


# ── Capture / spiral / eject ────────────────────────────────────────────

func _on_body_entered(body: Node3D) -> void:
	if _state != S.IDLE:
		return
	if body.is_in_group("player_body") or body is CharacterBody3D:
		_player = body
		_state = S.CAPTURED


func _on_body_exited(body: Node3D) -> void:
	if body == _player and _state == S.CAPTURED:
		_player = null
		_state = S.IDLE


func _physics_process(delta: float) -> void:
	# Visual rotation + core pulse.
	_spin_phase += delta * (spin_strength * 0.25 + 0.6)
	if is_instance_valid(_spinner):
		_spinner.rotation.y = _spin_phase
	if _core_mat:
		_core_mat.emission_energy_multiplier = 2.4 + 1.0 * sin(_spin_phase * 2.0)

	match _state:
		S.CAPTURED:
			_apply_vortex()
		S.COOLDOWN:
			_cooldown -= delta
			if _cooldown <= 0.0:
				_state = S.IDLE


func _apply_vortex() -> void:
	if not is_instance_valid(_player):
		_state = S.IDLE
		return
	var rel := _player.global_position - global_position
	rel.y = 0.0
	var radius := rel.length()
	if radius < eject_radius:
		_eject(rel)
		return
	var to_center := (-rel).normalized()
	var tangent := Vector3.UP.cross(rel).normalized()   # horizontal swirl
	var vel := to_center * pull_strength + tangent * spin_strength + Vector3.UP * lift
	if "velocity" in _player:
		_player.set("velocity", vel)


func _eject(rel: Vector3) -> void:
	var outward := rel.normalized() if rel.length() > 0.1 else Vector3(1, 0, 0)
	if is_instance_valid(_player) and "velocity" in _player:
		_player.set("velocity", outward * eject_force + Vector3.UP * eject_up)
	_player = null
	_state = S.COOLDOWN
	_cooldown = cooldown_time
	for m in _accent_mats:
		m.emission_energy_multiplier = 6.0


# ── Helpers ──────────────────────────────────────────────────────────────

func _emissive(color: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_accent_mats.append(m)
	return m


## Matte and translucent — the marks that are NOT light. Deliberately kept out of
## _accent_mats so the eject flash cannot make a stain or a drape glow.
func _dull(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.95
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m
