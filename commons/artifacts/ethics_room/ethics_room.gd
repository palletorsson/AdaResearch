extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name EthicsRoom

## @identity
## name: Ethics Room
## truth: Ethics is not a checkbox — it is the ongoing work.
##
## Ethical design after incompleteness — LARGE, room-scale (~7x7 floor y=-0.05).
## A room of design decisions: each slate pillar is a choice, and each casts a
## dark "shadow" on the floor — the set it excludes, made visible. The work is
## never finished: pillars slowly cycle through being re-decided (lift, glow
## amber = under review, settle), one at a time, forever. Overhead title.

@export var pillar_count: int = 6          # design decisions in the room
@export var cycle_period: float = 4.0      # seconds each pillar spends under review
@export var floor_extent: float = 6.4

const COOL_WHITE := Color(0.90, 0.92, 0.97)
const SLATE := Color(0.34, 0.38, 0.48)
const PURPLE := Color(0.58, 0.42, 0.92)
const TEAL := Color(0.30, 0.82, 0.78)
const AMBER := Color(0.98, 0.72, 0.28)
const SHADOW := Color(0.04, 0.04, 0.08)

var _pillars: Array[MeshInstance3D] = []
var _pillar_mats: Array[StandardMaterial3D] = []
var _caps: Array[MeshInstance3D] = []
var _shadows: Array[MeshInstance3D] = []
var _base_y: Array[float] = []
var _ring: MeshInstance3D = null
var _t: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_pillars.clear()
	_pillar_mats.clear()
	_caps.clear()
	_shadows.clear()
	_base_y.clear()

	# --- Room floor (cool slate slab) --------------------------------------
	add_child(_box(Vector3(0, -0.05, 0), Vector3(7.0, 0.08, 7.0), _matte_mat(Color(0.16, 0.17, 0.21), 0.9)))

	# Purple wireframe perimeter — the formal frame of the decision space.
	var wire_mat: StandardMaterial3D = _glow_mat(PURPLE, 1.1)
	var hx: float = floor_extent * 0.5
	add_child(_box(Vector3(0, 0.02, hx), Vector3(floor_extent, 0.02, 0.02), wire_mat))
	add_child(_box(Vector3(0, 0.02, -hx), Vector3(floor_extent, 0.02, 0.02), wire_mat))
	add_child(_box(Vector3(hx, 0.02, 0), Vector3(0.02, 0.02, floor_extent), wire_mat))
	add_child(_box(Vector3(-hx, 0.02, 0), Vector3(0.02, 0.02, floor_extent), wire_mat))

	# --- Pillars of decision around a circle, each with an exclusion shadow -
	var ring_r: float = floor_extent * 0.32
	for i in range(pillar_count):
		var a: float = TAU * float(i) / float(pillar_count)
		var px: float = cos(a) * ring_r
		var pz: float = sin(a) * ring_r

		# the exclusion shadow on the floor (offset outward from room centre)
		var shadow_off: Vector3 = Vector3(cos(a), 0.0, sin(a)) * 0.85
		var shadow: MeshInstance3D = _cylinder(Vector3(px + shadow_off.x, -0.04, pz + shadow_off.z), 0.55, 0.012, _matte_mat(SHADOW, 0.98))
		add_child(shadow)
		_shadows.append(shadow)
		# faint amber rim — the excluded set is acknowledged, not hidden
		add_child(_torus(Vector3(px + shadow_off.x, -0.03, pz + shadow_off.z), 0.55, 0.01, _glow_mat(AMBER * 0.7, 0.6)))

		# the pillar (a decision) — slate steel, varying heights
		var h: float = 2.0 + 0.4 * sin(float(i) * 1.7)
		var pmat: StandardMaterial3D = _steel_mat(SLATE)
		var pillar: MeshInstance3D = _cylinder(Vector3(px, h * 0.5, pz), 0.16, h, pmat)
		add_child(pillar)
		_pillars.append(pillar)
		_pillar_mats.append(pmat)
		_base_y.append(h * 0.5)

		# decision cap — glows teal when settled, amber when under review
		var cap_mat: StandardMaterial3D = _glow_mat(TEAL, 1.5)
		var cap: MeshInstance3D = _sphere(Vector3(px, h + 0.12, pz), 0.14, cap_mat)
		add_child(cap)
		_caps.append(cap)
		# store cap mat alongside pillar mat by reusing parallel index via cap.material_override
		add_child(_billboard_label("DECISION " + str(i + 1), Vector3(px, h + 0.4, pz), 16, COOL_WHITE))

	# --- A slow rotating "re-decision" ring at the centre (never finished) --
	_ring = _torus(Vector3(0, 1.2, 0), 0.9, 0.05, _glow_mat(AMBER, 1.6))
	add_child(_ring)
	add_child(_cylinder(Vector3(0, 0.6, 0), 0.05, 1.2, _steel_mat(SLATE)))
	add_child(_billboard_label("RE-DECIDING…", Vector3(0, 2.0, 0), 22, AMBER))

	# --- Overhead title ----------------------------------------------------
	add_child(_billboard_label("ETHICS IS NOT A CHECKBOX — IT IS THE ONGOING WORK", Vector3(0, 3.6, 0), 40, COOL_WHITE))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	# One pillar at a time enters "under review": lifts slightly, cap goes amber,
	# its exclusion shadow pulses. Then it settles and the next takes its turn.
	# The cycle never ends — the work is ongoing.
	var n: int = maxi(_pillars.size(), 1)
	var total: float = cycle_period * float(n)
	var global_phase: float = fmod(_t, total)
	var active: int = int(global_phase / cycle_period)
	var local: float = fmod(global_phase, cycle_period) / cycle_period
	# review intensity rises then falls within the slot
	var review: float = sin(local * PI)

	for i in range(_pillars.size()):
		var is_active: bool = (i == active)
		var amt: float = review if is_active else 0.0

		# lift the pillar under review
		var pillar: MeshInstance3D = _pillars[i]
		pillar.position.y = _base_y[i] + amt * 0.10

		# cap colour: teal settled -> amber under review
		if i < _caps.size():
			var cap: MeshInstance3D = _caps[i]
			var cm: StandardMaterial3D = cap.material_override
			if cm != null:
				var col: Color = TEAL.lerp(AMBER, amt)
				cm.albedo_color = col
				cm.emission = col
				cm.emission_energy_multiplier = (1.5 + amt * 1.5) if emissive else 0.0
			cap.position.y = (_base_y[i] * 2.0) + 0.12 + amt * 0.10

		# exclusion shadow pulses while its decision is re-examined
		if i < _shadows.size():
			var sh: MeshInstance3D = _shadows[i]
			var s: float = 1.0 + amt * 0.18
			sh.scale = Vector3(s, 1.0, s)

	# Central re-decision ring turns endlessly.
	if _ring != null:
		_ring.rotation.y = _t * 0.7
		_ring.rotation.x = sin(_t * 0.5) * 0.2
