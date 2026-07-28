# CAP Theorem Walk — pick two of three; the third stays dim
#
# Three pillars in a triangle, labeled "Consistency", "Availability", "Partition tolerance".
# A glowing line slowly cycles around the triangle, lighting two adjacent pillars at a time
# and dimming the third. At any moment, the lit pair tells you what the system has chosen;
# the dimmed pillar is what was given up.
#
# CAP is incompleteness for distributed systems: you cannot have all three. The walk makes
# the trade-off visible as a slow rotation, not a single fixed choice.
#
# A map can stop the rotation and name the trade instead — `#sacrifice:availability` knocks
# the Availability pillar down to a stump and lights the other two for good. `#sacrifice:whole`
# builds the impossible thing: all three standing, tied into a closed triangle.
#
# @identity
# essence: three pillars in a triangle — Consistency, Availability, Partition tolerance — and a light that can only ever hold two, the dim pillar naming today's sacrifice as the choice rotates
# desire: to show engineering living with a proven limit; the room needs CAP not as a warning but as a rhythm a system settles into
# critical_parameter: the rotation period of the lit pair — slow enough that each trade-off is legible as a chosen configuration, fast enough that no pair reads as the answer
# triggers: _ready() raises the triangle; _process cycles the glowing line around it, lighting adjacent pairs and dimming the third
# emerges: the trade space replaces the optimum — you stop asking which pair is right and start asking which sacrifice this moment can afford, which is how distributed systems are actually run
# needs: three CylinderMesh pillars [Godot built-ins]; on/off emissive materials; labels for the three properties; triangle_radius sized for walking around, not just viewing
# triggers_note: passive exhibit — the argument is carried entirely by the cycle
# relationships: the applied rung of the incompleteness ladder — godel_statement_plaque proves the limit, this shows a discipline building calmly inside it
# truth: CAP is incompleteness for distributed systems: you cannot have all three, and mature engineering is visible precisely in which third it chooses to give up, and when.
# @qfep_term: Edge — the trade space, not the optimum.

extends Node3D
class_name CAPTheoremWalk

@export var pillar_color_off: Color = Color(0.3, 0.32, 0.4, 1.0)
@export var pillar_color_on: Color = Color(0.95, 0.85, 0.3, 1.0)
@export var triangle_radius: float = 0.9
@export var pillar_height: float = 1.5
@export var cycle_speed: float = 0.3

## WHICH OF THE THREE THE SYSTEM GAVE UP — or whether it admits giving up anything.
##
## The artifact's whole content is a proven limit and the choice it forces, but until now
## the choice was delegated to a timer: every placement showed the same anonymous rotation,
## and a still caught it at an arbitrary phase, so the sacrifice read as decoration. Setting
## it lets a map about a real distributed system point at its own trade — Dynamo gave up C,
## a two-phase-commit bank gave up A, a single-box database gave up P — and `whole` renders
## the fantasy CAP disproves, which is this sequence's question asked from the wrong side.
##
## The amputation is PHYSICAL, not a dimmer. A pillar that is given up is knocked down to a
## 0.55 m stump with its own rubble at the foot: legible from across the room, where a
## difference in emission energy is not. `cycle` is the legacy look and changes nothing.
@export_enum("cycle", "consistency", "availability", "partition", "whole") var sacrifice: String = "cycle"

const SACRIFICES: PackedStringArray = [
	"cycle", "consistency", "availability", "partition", "whole"]

## Which pillar index each named value knocks down. `cycle` and `whole` fell nothing.
const SACRIFICE_INDEX: Dictionary = {
	"consistency": 0,
	"availability": 1,
	"partition": 2,
}

## The stump left where a pillar was. A third of full height and no more — at 1.0 m it
## would still read as a pillar seen from a distance; at 0.55 m it reads as a break.
const STUMP_HEIGHT: float = 0.55

## Rubble: three 0.18 m boxes at the stump's foot, so the missing 0.95 m is accounted for
## on the floor instead of just being absent.
const RUBBLE_SIZE: float = 0.18
const RUBBLE_OFFSETS: Array = [
	Vector3(0.26, 0.0, 0.07),
	Vector3(-0.19, 0.0, 0.22),
	Vector3(0.05, 0.0, -0.27),
]
const RUBBLE_YAW: Array = [0.35, -0.62, 1.05]

## `whole`: the closed circuit CAP proves impossible — three 0.10 m beams tying the pillar
## tops into a triangle. Nothing else in the artifact draws a closed loop, which is the point.
const BEAM_THICKNESS: float = 0.10

const PILLAR_NAMES: Array = ["Consistency", "Availability", "Partition\ntolerance"]

var _pillars: Array = []  # 3 pillars, ordered C, A, P
var _labels: Array = []
var _extras: Array = []   # rubble boxes and crown beams
var _built: bool = false
var _cycle_active: bool = true
var _t: float = 0.0


func _ready() -> void:
	# SYNCHRONOUS. Children exist by the time _ready returns, so the grid's
	# LabelFramer / auto-ground passes measure the finished thing.
	_build_all()
	_built = true


# ═══════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════

func _build_all() -> void:
	# Only the timer-driven default keeps rotating the dim index. Every named sacrifice
	# is a fixed fact about a system, so it must not be animated over.
	_cycle_active = (sacrifice == "cycle")
	var fallen: int = int(SACRIFICE_INDEX.get(sacrifice, -1))

	for i in 3:
		var a: float = TAU * float(i) / 3.0 - PI * 0.5
		var foot := Vector3(cos(a) * triangle_radius, 0.0, sin(a) * triangle_radius)
		var is_fallen: bool = (i == fallen)
		var h: float = STUMP_HEIGHT if is_fallen else pillar_height

		var pillar := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.22, h, 0.22)
		pillar.mesh = box
		pillar.material_override = _make_material(pillar_color_off, 0.3)
		pillar.position = foot + Vector3(0, h * 0.5, 0)
		add_child(pillar)
		_pillars.append(pillar)

		# Standing pillars under a named sacrifice (and under `whole`) are lit for good —
		# the trade has been made, there is nothing left to cycle.
		if not _cycle_active and not is_fallen:
			_light(pillar, true)

		if is_fallen:
			_build_rubble(foot)

		var label := Label3D.new()
		label.text = PILLAR_NAMES[i]
		label.font_size = 15
		label.outline_size = 4
		label.modulate = pillar_color_on
		# The label follows the top it names. On a stump it drops with the pillar, so the
		# fall is readable in the text row as well as in the silhouette.
		label.position = foot + Vector3(0, h + 0.16, 0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(label)
		_labels.append(label)

	if sacrifice == "whole":
		_build_crown()


## Three boxes of debris at the foot of a knocked-down pillar.
func _build_rubble(foot: Vector3) -> void:
	for r in RUBBLE_OFFSETS.size():
		var off: Vector3 = RUBBLE_OFFSETS[r]
		var chunk := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(RUBBLE_SIZE, RUBBLE_SIZE, RUBBLE_SIZE)
		chunk.mesh = box
		chunk.material_override = _make_material(pillar_color_off, 0.3)
		chunk.position = foot + off + Vector3(0, RUBBLE_SIZE * 0.5, 0)
		chunk.rotation.y = float(RUBBLE_YAW[r])
		add_child(chunk)
		_extras.append(chunk)


## The closed triangle at pillar-top height — all three held at once, which is exactly
## what the theorem says cannot be built.
func _build_crown() -> void:
	for i in 3:
		var a0: float = TAU * float(i) / 3.0 - PI * 0.5
		var a1: float = TAU * float((i + 1) % 3) / 3.0 - PI * 0.5
		var p0 := Vector3(cos(a0) * triangle_radius, pillar_height, sin(a0) * triangle_radius)
		var p1 := Vector3(cos(a1) * triangle_radius, pillar_height, sin(a1) * triangle_radius)
		var d: Vector3 = p1 - p0
		var span: float = d.length()
		var beam := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(span, BEAM_THICKNESS, BEAM_THICKNESS)
		beam.mesh = box
		beam.material_override = _make_material(pillar_color_on, 2.0)
		beam.position = p0 + d * 0.5
		beam.rotation.y = atan2(-d.z, d.x)
		add_child(beam)
		_extras.append(beam)


func _make_material(col: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = energy
	return mat


func _light(pillar: MeshInstance3D, on: bool) -> void:
	var mat := pillar.material_override as StandardMaterial3D
	if not mat:
		return
	if on:
		mat.albedo_color = pillar_color_on
		mat.emission = pillar_color_on
		mat.emission_energy_multiplier = 2.0
	else:
		mat.albedo_color = pillar_color_off
		mat.emission = pillar_color_off
		mat.emission_energy_multiplier = 0.3


## Tear down ONLY the nodes this script created — tracked in _pillars/_labels/_extras —
## and build again inline. Anything the grid system parented to us (label plates,
## packaging, tags) is never touched. remove_child before queue_free so the old geometry
## leaves the tree synchronously and never double-renders against the new.
func _rebuild_now() -> void:
	var all: Array = []
	all.append_array(_pillars)
	all.append_array(_labels)
	all.append_array(_extras)
	for n in all:
		if is_instance_valid(n) and n is Node:
			var node: Node = n
			if node.get_parent() == self:
				remove_child(node)
			node.queue_free()
	_pillars.clear()
	_labels.clear()
	_extras.clear()
	_build_all()


# ═══════════════════════════════════════════════════════════════════
# GRID CONFIG INTEGRATION
# ═══════════════════════════════════════════════════════════════════

## A config that changes nothing geometric must leave the artifact exactly as it stands.
## curation_station curates already-shipped placements by framing their labels and then
## calling this with `{"emissive": false}` — no axis key at all. Rebuilding on that call
## threw away the framing and re-lit billboarded, outlined labels in a vitrine that had
## just asked for the opposite. So: snapshot, resolve, and only rebuild on a real change.
func apply_grid_config(config_data: Dictionary) -> void:
	var before_sacrifice: String = sacrifice

	# Stage-2 DNA axis — #sacrifice:availability
	if config_data.has("sacrifice"):
		sacrifice = _pick_axis(str(config_data["sacrifice"]), SACRIFICES, sacrifice)

	if not _built:
		return  # _ready has not run yet; it will build with these values. Do NOT build here.
	if sacrifice == before_sacrifice:
		return  # nothing geometric changed — this is curation_station's {"emissive": false}
	_rebuild_now()
	print("[CAPTheoremWalk] Config applied — sacrifice=%s" % [sacrifice])


## Accept an axis value only if it names something we actually build. A typo in a map
## token has to land on the legacy look — a half-recognised value would strand a
## placement between two builds and pretend a system named a trade it never named.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


func _process(delta: float) -> void:
	if not _cycle_active:
		return
	if _pillars.size() < 3:
		return
	_t += delta * cycle_speed
	# Which two are lit?
	var phase: float = fmod(_t, 3.0)
	var dim_idx: int = int(phase)  # 0,1,2 cycles
	for i in 3:
		var pillar: MeshInstance3D = _pillars[i]
		_light(pillar, i != dim_idx)
