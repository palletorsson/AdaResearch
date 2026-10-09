# schrodinger_box.gd
# Schrödinger's cat thought experiment visualization
# The box holds superposition until observed

extends Node3D

class_name SchrodingerBox

# @identity
# essence: |ψ⟩ = α|alive⟩ + β|dead⟩ → observation collapses to |alive⟩ or |dead⟩ with P = |α|²
# desire: open the box and watch the superposition collapse — the lid swings, the state resolves, then resets
# critical_parameter: remainder — where the box puts the part of the state it cannot show you (core | twin | seam | haze | witness); vantage — whether the argument is an object you hold or a room you stand in (specimen | stele | chamber). auto_reset_time is tempo, not stance: it sets how long the collapsed state persists.
# triggers: click/observe collapses the wavefunction randomly; timer resets to superposition; lid animates open/close; apply_grid_config({remainder, vantage, box_size, auto_reset_time})
# emerges: the discomfort of genuine indeterminacy — the cat is not secretly alive or dead, it is both
# needs: VR click interaction [has via mouse], XR interaction [missing]
# relationships: contrasts florensky_sphere (quantum vs paraconsistent superposition); paired with superposition_display (abstract vs physical metaphor) — the two share one `remainder`/`vantage` vocabulary
# truth: observation does not reveal a pre-existing state — it creates one

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-07-27). Kin pair with superposition_display; the
# two share one vocabulary and were promoted together.
#
# WHY NOT THE OBVIOUS AXIS. Every reflex for this object is temporal — sealed
# then opened, superposed then collapsed, a BEFORE and an AFTER. That framing is
# invisible to a still frame, and worse, it smuggles back exactly the classical
# picture the object exists to unsettle: it says there was always a fact and the
# lid was merely in the way. Schrödinger wrote the box as a reductio, not as a
# suspense device.
#
# So the axis is spatial, and it is the one thing a box can actually argue
# about: WHAT IT DOES WITH THE FACT THAT YOU ARE OUTSIDE IT.
#
#   remainder   where the object puts the part of the state it cannot show
#   vantage     whether the argument is an object you hold or a room you stand in
#
# `remainder` is the project's own third sieve question made into geometry. Q3
# asks what lives in the dark spot; CONSERVATION_OF_THE_IRREDUCIBLE §5 answers
# that the dark spot is never empty — you can move the irreducible, never remove
# it, and "the machine's only freedom is where to put the pile." The
# interpretations of quantum mechanics are precisely a disagreement about where
# the pile goes, and each one has a shape:
#
#   core     the pile stays sealed inside a solid body. A fact exists; you lack
#            access to it. This is the legacy build and it is the most classical
#            claim in the family — ignorance dressed as physics.
#   twin     there is no pile, because both outcomes are actual. The sealed body
#            is gone; two open cells stand where it was, each with a definite,
#            permanently visible occupant, and a bright wall between them that
#            they cannot talk across.
#   seam     the pile is the boundary. The body is sliced and held apart on four
#            glowing posts; between the halves is an unlit, unfilled slot. The
#            object marks the cut it cannot justify instead of papering it over.
#   haze     there is no inside to seal. The walls are only edges, the interior
#            leaks, and the room around the box is full of faint half-outcomes:
#            the environment was always already measuring.
#   witness  the pile is you. The box has no front — it opens toward whoever is
#            asking, and where the state would be there is a polished plate
#            returning the room. No view from nowhere.
#
# `vantage` is the second thing a limit can differ in: whether you are shown it
# or standing in it. A hand-sized box on a plinth is a paradox safely framed; a
# room-scale one is a paradox you are inside, with no exterior to retreat to.
#
#   specimen  legacy: 0.4 m, below your eyeline, an exhibit you look down on
#   stele     lifted to eye height against an upright slab — it addresses you
#   chamber   scaled 3.8× inside a three-walled shell — you are within it
#
# R1: remainder=core + vantage=specimen reproduces the 2026 build exactly. See
# _apply_staging(): on the legacy pair it frees nothing, writes two identity
# transforms, and returns before a single node is created. The box, lid, cats,
# glow and both labels are built by the untouched original functions with their
# original literals; the only structural change is that they now hang off a
# Body node at the identity transform so `vantage` has something to move.
# _update_display(), observe(), reset_to_superposition() and _process() are not
# altered: every variant is additive scenery plus, at most, hiding a mesh that
# is occluded anyway in the default.
#
# WHAT IS FORECLOSED. `core` is now one opinion among five rather than the
# unmarked way a box is. That is the point, but it costs something real: a
# reader who wants "the Schrödinger box" now has to be told which one, and the
# neutral reading — the box as a settled illustration in a textbook — is harder
# to hold. Also foreclosed: reading this artifact as an animation. Four of the
# five variants make their whole claim standing still, which quietly argues that
# the temporal staging was never carrying the argument.
#
# NOT ROUTED THROUGH EITHER AXIS, on purpose: the collapse itself. observe()
# still rolls randf() > 0.5 and the labels still say what they said. Where the
# indeterminacy is kept is a staging question; whether it is real is the
# curriculum's, and not this pass's to answer.
# ─────────────────────────────────────────────────────────────────────────────

signal box_opened
signal state_collapsed(is_alive: bool)
signal superposition_entered

enum State { SUPERPOSITION, ALIVE, DEAD }

@export var box_size: Vector3 = Vector3(0.4, 0.3, 0.3)
@export var current_state: State = State.SUPERPOSITION
@export var auto_reset_time: float = 5.0

## AXIS 1 — where the box puts the part of the state it cannot show you.
## core (legacy default) | twin | seam | haze | witness. Shared verbatim with
## superposition_display; #remainder: parses through remainder_name().
@export_enum("core", "twin", "seam", "haze", "witness") var remainder: String = "core"
## AXIS 2 — whether the limit is an object in front of you or a room around you.
## specimen (legacy default) | stele | chamber. `chamber` is deliberately larger
## than the registry footprint [1,1,1]: a map that opts into it is asking for a
## room, and should give the artifact the cells.
@export_enum("specimen", "stele", "chamber") var vantage: String = "specimen"

## Spellings that mean the same stance. Kept so the pair's two files, and any
## map that learns one word, cannot drift apart. An absence is spelled "none"
## everywhere in this codebase — there is no absence on this axis, because every
## variant does something with the remainder, including refusing to.
const REMAINDER_ALIASES := {
	"sealed": "core",       # participle for the legacy body
	"branch": "twin",       # the many-worlds reading, by its physics name
	"cut": "seam",          # the Heisenberg cut — the project's word is seam
	"leak": "haze",         # what decoherence does, named as the verb
	"mirror": "witness",    # the material, not the claim
}

## The pair's one reader for a remainder token. Static so superposition_display
## parses #remainder: through this exact function rather than its own table.
static func remainder_name(raw: String) -> String:
	var v: String = str(raw).strip_edges().to_lower()
	return str(REMAINDER_ALIASES.get(v, v))

const VANTAGE_ALIASES := {
	"object": "specimen",
	"panel": "stele",
	"room": "chamber",
}

## The twin of remainder_name(). Also static, also shared with the display.
static func vantage_name(raw: String) -> String:
	var v: String = str(raw).strip_edges().to_lower()
	return str(VANTAGE_ALIASES.get(v, v))

var _xr_active: bool = false
var _box_mesh: MeshInstance3D
var _lid_mesh: MeshInstance3D
var _cat_alive: MeshInstance3D
var _cat_dead: MeshInstance3D
var _superposition_glow: MeshInstance3D
var _label: Label3D
var _state_label: Label3D
var _lid_open: bool = false
var _reset_timer: float = 0.0

# The object, at object scale. Identity transform in the legacy build; `vantage`
# moves and scales this and nothing else, so the original create functions keep
# their original numbers.
var _body: Node3D
# Remainder geometry that belongs to the OBJECT (rides the vantage scale).
var _shell: Node3D
# Vantage geometry that belongs to the ROOM (does not ride it).
var _stage: Node3D
# False when the variant's argument is that nothing is kept at the core. Read at
# the end of _update_display(); true on the legacy path, where the block is dead.
var _core_shown: bool = true
var _built_remainder: String = ""
var _built_vantage: String = ""

func _ready():
	_xr_active = XRServer.primary_interface != null
	remainder = remainder_name(remainder)
	vantage = vantage_name(vantage)
	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)
	_create_box()
	_create_lid()
	_create_cat_states()
	_create_superposition_effect()
	_create_labels()
	_apply_staging()

func _create_box():
	_box_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = box_size
	_box_mesh.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.25, 0.2)
	mat.metallic = 0.1
	mat.roughness = 0.8
	_box_mesh.material_override = mat
	_body.add_child(_box_mesh)

func _create_lid():
	_lid_mesh = MeshInstance3D.new()
	var lid = BoxMesh.new()
	lid.size = Vector3(box_size.x * 1.05, 0.02, box_size.z * 1.05)
	_lid_mesh.mesh = lid
	_lid_mesh.position.y = box_size.y / 2 + 0.01

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.3, 0.25)
	mat.metallic = 0.2
	mat.roughness = 0.7
	_lid_mesh.material_override = mat
	_body.add_child(_lid_mesh)

func _create_cat_states():
	# Alive cat (happy sphere)
	_cat_alive = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.08
	sphere.height = 0.16
	_cat_alive.mesh = sphere
	_cat_alive.position = Vector3(0, 0, 0)
	_cat_alive.visible = false

	var alive_mat = StandardMaterial3D.new()
	alive_mat.albedo_color = Color(0.3, 0.8, 0.3)
	alive_mat.emission_enabled = true
	alive_mat.emission = Color(0.2, 0.6, 0.2)
	alive_mat.emission_energy_multiplier = 0.5
	_cat_alive.material_override = alive_mat
	_body.add_child(_cat_alive)

	# Dead cat (flat shape)
	_cat_dead = MeshInstance3D.new()
	var dead_box = BoxMesh.new()
	dead_box.size = Vector3(0.15, 0.03, 0.1)
	_cat_dead.mesh = dead_box
	_cat_dead.position = Vector3(0, -box_size.y / 2 + 0.025, 0)
	_cat_dead.visible = false

	var dead_mat = StandardMaterial3D.new()
	dead_mat.albedo_color = Color(0.4, 0.4, 0.4)
	_cat_dead.material_override = dead_mat
	_body.add_child(_cat_dead)

func _create_superposition_effect():
	_superposition_glow = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.24
	_superposition_glow.mesh = sphere
	_superposition_glow.position = Vector3(0, 0, 0)

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.3, 0.8, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.4, 0.2, 0.7)
	mat.emission_energy_multiplier = 0.8
	_superposition_glow.material_override = mat
	_body.add_child(_superposition_glow)

func _create_labels():
	_label = Label3D.new()
	_label.pixel_size = 0.001
	_label.font_size = 14
	_label.text = "SCHRÖDINGER'S BOX\nClick to observe"
	_label.position = Vector3(0, -box_size.y / 2 - 0.1, 0)
	_body.add_child(_label)

	_state_label = Label3D.new()
	_state_label.pixel_size = 0.001
	_state_label.font_size = 16
	_state_label.position = Vector3(0, box_size.y / 2 + 0.1, 0)
	_body.add_child(_state_label)

func _update_display():
	match current_state:
		State.SUPERPOSITION:
			_cat_alive.visible = false
			_cat_dead.visible = false
			_superposition_glow.visible = true
			_state_label.text = "|ψ⟩ = α|alive⟩ + β|dead⟩"
			_state_label.modulate = Color(0.7, 0.5, 1.0)
		State.ALIVE:
			_cat_alive.visible = true
			_cat_dead.visible = false
			_superposition_glow.visible = false
			_state_label.text = "COLLAPSED: |alive⟩"
			_state_label.modulate = Color(0.3, 1.0, 0.3)
		State.DEAD:
			_cat_alive.visible = false
			_cat_dead.visible = true
			_superposition_glow.visible = false
			_state_label.text = "COLLAPSED: |dead⟩"
			_state_label.modulate = Color(0.8, 0.3, 0.3)
	# Variants whose whole claim is that nothing is kept at the core stop drawing
	# it. Dead code on the legacy path — _core_shown is only ever false after a
	# remainder token has been read.
	if not _core_shown:
		_cat_alive.visible = false
		_cat_dead.visible = false
		_superposition_glow.visible = false

func _process(delta):
	# Animate superposition
	if current_state == State.SUPERPOSITION:
		var t = Time.get_ticks_msec() / 1000.0
		var mat = _superposition_glow.material_override as StandardMaterial3D
		mat.albedo_color.a = 0.3 + 0.3 * sin(t * 3.0)
		mat.emission_energy_multiplier = 0.5 + 0.3 * sin(t * 2.0)

	# Auto reset after collapse
	if current_state != State.SUPERPOSITION and auto_reset_time > 0:
		_reset_timer += delta
		if _reset_timer >= auto_reset_time:
			reset_to_superposition()

func observe():
	if current_state == State.SUPERPOSITION:
		# Collapse the wavefunction
		var is_alive = randf() > 0.5
		current_state = State.ALIVE if is_alive else State.DEAD
		_reset_timer = 0.0

		# Open lid
		var tween = create_tween()
		tween.tween_property(_lid_mesh, "rotation_degrees:x", -110, 0.5)
		_lid_open = true

		_update_display()
		box_opened.emit()
		state_collapsed.emit(is_alive)

func reset_to_superposition():
	current_state = State.SUPERPOSITION
	_reset_timer = 0.0

	# Close lid
	if _lid_open:
		var tween = create_tween()
		tween.tween_property(_lid_mesh, "rotation_degrees:x", 0, 0.5)
		_lid_open = false

	_update_display()
	superposition_entered.emit()

func _input(event):
	if _xr_active:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if current_state == State.SUPERPOSITION:
				observe()
			else:
				reset_to_superposition()

# ─────────────────────────────────────────────────────────────────────────────
# STAGING
# ─────────────────────────────────────────────────────────────────────────────

## Rebuild the two staging layers from the current axis values. Idempotent, and
## on the legacy pair it does nothing but write two transforms it already holds.
func _apply_staging() -> void:
	if _shell != null:
		_shell.queue_free()
		_shell = null
	if _stage != null:
		_stage.queue_free()
		_stage = null
	_core_shown = true
	_box_mesh.visible = true
	_lid_mesh.visible = true
	_body.scale = Vector3.ONE
	_body.position = Vector3.ZERO
	_built_remainder = remainder
	_built_vantage = vantage

	if not (remainder == "core" and vantage == "specimen"):
		_stage = Node3D.new()
		_stage.name = "Stage"
		add_child(_stage)
		_shell = Node3D.new()
		_shell.name = "Shell"
		_body.add_child(_shell)
		_stage_vantage()
		_stage_remainder()

	_update_display()

func _stage_vantage() -> void:
	var stone := _surface(Color(0.20, 0.20, 0.22), 0.88, 0.0, 0.0)
	match vantage:
		"stele":
			# Lifted to eye height against an upright slab: the paradox posted in
			# public, addressing you at your own height rather than under it.
			_body.scale = Vector3.ONE * 1.7
			_body.position = Vector3(0, 1.32, 0)
			_slab(_stage, Vector3(0.98, 2.15, 0.16), Vector3(0, 1.075, -0.34), stone)
			_slab(_stage, Vector3(1.24, 0.09, 0.66), Vector3(0, 0.045, -0.12), stone)
		"chamber":
			# No exterior to retreat to. Three walls and a floor at room scale,
			# the box itself 1.5 m across at eye height in the middle of them.
			_body.scale = Vector3.ONE * 3.8
			_body.position = Vector3(0, 1.58, 0)
			_slab(_stage, Vector3(4.6, 0.08, 4.6), Vector3(0, 0.04, 0), stone)
			_slab(_stage, Vector3(4.6, 2.9, 0.14), Vector3(0, 1.45, -2.3), stone)
			_slab(_stage, Vector3(0.14, 2.9, 4.6), Vector3(-2.3, 1.45, 0), stone)
			_slab(_stage, Vector3(0.14, 2.9, 4.6), Vector3(2.3, 1.45, 0), stone)

func _stage_remainder() -> void:
	var hx: float = box_size.x * 0.5
	var hy: float = box_size.y * 0.5
	var hz: float = box_size.z * 0.5
	var signs: Array[float] = [-1.0, 1.0]
	var wood := _surface(Color(0.30, 0.25, 0.20), 0.8, 0.1, 0.0)

	match remainder:
		"twin":
			# Both outcomes are actual, so there is nothing left to seal. Two open
			# cells, each with a permanently visible definite occupant, and a wall
			# between them they cannot see across.
			_box_mesh.visible = false
			_lid_mesh.visible = false
			_core_shown = false
			var t: float = 0.014
			for s in signs:
				var cell := Node3D.new()
				cell.position = Vector3(s * box_size.x * 1.10, 0, 0)
				_shell.add_child(cell)
				_slab(cell, Vector3(box_size.x, t, box_size.z), Vector3(0, -hy, 0), wood)
				_slab(cell, Vector3(box_size.x, box_size.y, t), Vector3(0, 0, -hz), wood)
				for sx in signs:
					_slab(cell, Vector3(t, box_size.y, box_size.z), Vector3(sx * hx, 0, 0), wood)
			var live := _surface(Color(0.30, 0.80, 0.30), 0.5, 0.0, 0.9)
			_ball(_shell, 0.082, Vector3(-box_size.x * 1.10, -hy + 0.095, 0), live)
			var gone := _surface(Color(0.42, 0.42, 0.44), 0.9, 0.0, 0.0)
			_slab(_shell, Vector3(0.16, 0.032, 0.11), Vector3(box_size.x * 1.10, -hy + 0.030, 0), gone)
			var wall := _surface(Color(0.88, 0.90, 0.96), 0.3, 0.2, 1.4)
			_slab(_shell, Vector3(0.010, box_size.y * 1.25, box_size.z), Vector3(0, 0, 0), wall)

		"seam":
			# The cut is the honest subject. Body sliced, halves held apart on four
			# bright posts, and between them an unlit slot that is left unfilled.
			_box_mesh.visible = false
			_core_shown = false
			var gap: float = 0.078
			var half_h: float = (box_size.y - gap) * 0.5
			_slab(_shell, Vector3(box_size.x, half_h, box_size.z), Vector3(0, hy - half_h * 0.5, 0), wood)
			_slab(_shell, Vector3(box_size.x, half_h, box_size.z), Vector3(0, -hy + half_h * 0.5, 0), wood)
			var post := _surface(Color(0.86, 0.93, 1.00), 0.22, 0.4, 2.4)
			for sx in signs:
				for sz in signs:
					_slab(_shell, Vector3(0.014, gap, 0.014),
						Vector3(sx * (hx - 0.022), 0, sz * (hz - 0.022)), post)
			var nothing := _surface(Color(0.02, 0.02, 0.03), 1.0, 0.0, 0.0)
			nothing.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			_slab(_shell, Vector3(box_size.x * 0.97, gap * 0.90, box_size.z * 0.97), Vector3.ZERO, nothing)

		"haze":
			# Nothing was ever isolated. The walls are only edges now, the interior
			# shows through, and the room is full of faint half-outcomes.
			_box_mesh.visible = false
			var bar := _surface(Color(0.36, 0.31, 0.26), 0.8, 0.1, 0.0)
			var t2: float = 0.013
			for sx in signs:
				for sz in signs:
					_slab(_shell, Vector3(t2, box_size.y, t2), Vector3(sx * hx, 0, sz * hz), bar)
			for sy in signs:
				for sz in signs:
					_slab(_shell, Vector3(box_size.x, t2, t2), Vector3(0, sy * hy, sz * hz), bar)
				for sx in signs:
					_slab(_shell, Vector3(t2, t2, box_size.z), Vector3(sx * hx, sy * hy, 0), bar)
			var live_g := _surface(Color(0.30, 0.80, 0.30, 0.55), 0.6, 0.0, 0.7)
			live_g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			var gone_g := _surface(Color(0.58, 0.58, 0.62, 0.45), 0.9, 0.0, 0.2)
			gone_g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			var rng := RandomNumberGenerator.new()
			rng.seed = 20260727
			for i in range(28):
				var ang: float = rng.randf() * TAU
				var rad: float = 0.24 + rng.randf() * 0.32
				var p := Vector3(cos(ang) * rad, (rng.randf() - 0.32) * 0.44, sin(ang) * rad)
				var rr: float = 0.016 + rng.randf() * 0.024
				_ball(_shell, rr, p, live_g if (i % 2 == 0) else gone_g)

		"witness":
			# There is no view from nowhere. The box opens toward whoever is asking,
			# and inside the opening is a plate that hands the room back.
			_box_mesh.visible = false
			_core_shown = false
			var t3: float = 0.018
			_slab(_shell, Vector3(box_size.x, t3, box_size.z), Vector3(0, -hy + t3 * 0.5, 0), wood)
			_slab(_shell, Vector3(box_size.x, box_size.y, t3), Vector3(0, 0, -hz + t3 * 0.5), wood)
			for sx in signs:
				_slab(_shell, Vector3(t3, box_size.y, box_size.z), Vector3(sx * (hx - t3 * 0.5), 0, 0), wood)
			var plate := _surface(Color(0.94, 0.96, 0.99), 0.04, 1.0, 0.55)
			_slab(_shell, Vector3(box_size.x - 0.055, box_size.y - 0.055, 0.014),
				Vector3(0, 0, hz - 0.055), plate)
			var rim := _surface(Color(0.98, 0.88, 0.58), 0.28, 0.5, 1.8)
			_slab(_shell, Vector3(box_size.x, 0.011, 0.011), Vector3(0, hy, hz), rim)
			_slab(_shell, Vector3(box_size.x, 0.011, 0.011), Vector3(0, -hy, hz), rim)
			for sx in signs:
				_slab(_shell, Vector3(0.011, box_size.y, 0.011), Vector3(sx * hx, 0, hz), rim)

# ── small builders ───────────────────────────────────────────────────────────

static func _surface(c: Color, rough: float, metal: float, emit: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = Color(c.r, c.g, c.b)
		m.emission_energy_multiplier = emit
	return m

func _slab(parent: Node3D, size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi

func _ball(parent: Node3D, r: float, pos: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	mi.mesh = sm
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi

func apply_grid_config(config_data: Dictionary):
	for key in config_data:
		if key in self:
			set(key, config_data[key])
	remainder = remainder_name(remainder)
	vantage = vantage_name(vantage)
	# Rebuild ONLY when a staging axis actually moved. capture_dna_sweep.gd calls
	# this on a live node, so the variant has to take effect after _ready();
	# every other caller in the codebase passes neither token and gets the same
	# no-op it got before this pass.
	if _body != null and (remainder != _built_remainder or vantage != _built_vantage):
		_apply_staging()
