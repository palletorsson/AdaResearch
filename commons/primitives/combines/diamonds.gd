# DiamondTower.gd
extends Node3D

# @identity
# essence: diamonds[i].rotation_y = twist_rule(i) — a tower of solids each rotated by an accumulating angle
# desire: learner sees how repetition with incremental rotation creates emergent spiral form from simple rule
# critical_parameter: twist_rule — HOW the angle accumulates over i; linear gives the helix, fixed gives a stack
# triggers: nothing at runtime — the pattern is baked into instance transforms at ready(); rebuilt on apply_grid_config
# emerges: the helix as a consequence of uniform angular accumulation — not designed, derived
# needs: [missing VR controls — static; would benefit from live rotation_offset slider]
# relationships: uses octahedron as its unit; sibling to combine_portals in the combines category
# truth: complex regular patterns emerge from simple repeated rules — the rule is more fundamental than the result
#
# STAGE-2 DNA PROMOTION (2026-07-29). The artifact's own truth statement says the
# RULE is more fundamental than the result — and yet the rule was the one thing
# hard-coded. `rotation.y = deg_to_rad(rotation_offset * i)` is linear accumulation,
# stated once, never varied. The knobs it did expose (count, size, height) only ever
# changed how BIG the same claim was. Two axes now make the claim testable:
#
#   twist_rule  how the angle accumulates   linear · fixed · alternating · accelerating
#   unit        the solid the rule acts on  octahedron · cube · tetrahedron · icosahedron
#
# twist_rule varies the rule while holding the unit; unit varies the unit while
# holding the rule. Between them you can see which half the helix comes from.
# `fixed` is the null hypothesis the docstring already named — every unit turned by
# the same amount, no accumulation, no helix, just a stack that has been rotated.
# `accelerating` reaches the SAME total twist at the top as `linear` does, by a
# different path: the endpoints agree and the form does not.
#
# twist_rule=linear + unit=octahedron is the pre-promotion behaviour exactly, and it
# is the default, so the 11 existing placements are untouched.
#
# Usage in map_data.json:
#   "diamonds"
#   "diamonds#twist_rule:fixed"
#   "diamonds#twist_rule:accelerating#unit:tetrahedron"

## The solids this tower can be built from. All are unit-scale, origin-centred
## members of the primitives family, so the tower's proportions survive the swap.
const UNIT_SCENES := {
	"octahedron": "res://commons/primitives/octahedron/octahedron.tscn",
	"cube": "res://commons/primitives/cube/cube.tscn",
	"tetrahedron": "res://commons/primitives/tetrahedron/tetrahedron.tscn",
	"icosahedron": "res://commons/primitives/icosahedron/icosahedron.tscn",
}

@export var unit_count := 12
@export var unit_size := 2.5
@export var unit_height := 2.0
@export var rotation_offset := 15.0 # degrees per step twist
## How the angle accumulates up the tower. linear = offset * i (the helix, and the
## legacy behaviour); fixed = every unit turned by offset, no accumulation;
## alternating = the step flips sign each unit, so the tower braids between two
## orientations instead of winding; accelerating = same total twist at the top as
## linear, reached superlinearly, so the spiral tightens with height.
@export var twist_rule: String = "linear"
## Which solid is stacked. The rule is the same in every case — this is the control.
@export var unit: String = "octahedron"

var _units: Array[Node3D] = []
var _built: bool = false


func _ready() -> void:
	_build()


func _build() -> void:
	for old in _units:
		if is_instance_valid(old):
			old.queue_free()
	_units.clear()

	var scene_path: String = str(UNIT_SCENES.get(unit, UNIT_SCENES["octahedron"]))
	var unit_scene: PackedScene = load(scene_path) as PackedScene
	if unit_scene == null:
		unit_scene = load(str(UNIT_SCENES["octahedron"])) as PackedScene
	if unit_scene == null:
		return

	# stack alternating "diamonds" using the chosen unit scene
	for i in range(unit_count):
		var step: int = int(i)
		var diamond: Node3D = unit_scene.instantiate() as Node3D
		if diamond == null:
			continue
		diamond.position = Vector3(0, unit_height * step + unit_height, 0)
		diamond.rotation.y = deg_to_rad(_twist_degrees(step))
		diamond.scale = Vector3(unit_size, unit_height, unit_size)
		add_child(diamond)
		_units.append(diamond)
	_built = true


## The rule itself, lifted out of the loop so there can be more than one of it.
func _twist_degrees(step: int) -> float:
	match twist_rule:
		"fixed":
			# no accumulation — every unit turned by the same amount
			return rotation_offset
		"alternating":
			# the step reverses each unit, so the angle never gets anywhere:
			# the tower braids between two orientations
			return rotation_offset * float(step % 2)
		"accelerating":
			# same total twist at the top as linear, distributed superlinearly
			var span: float = float(max(unit_count - 1, 1))
			return rotation_offset * float(step * step) / span
		_:
			# LEGACY LINEAGE — untouched. Uniform angular accumulation: the helix.
			return rotation_offset * float(step)


func apply_grid_config(config_data: Dictionary) -> void:
	var rebuild: bool = false
	if config_data.has("twist_rule"):
		var rule: String = str(config_data["twist_rule"])
		if rule != twist_rule:
			twist_rule = rule
			rebuild = true
	if config_data.has("unit"):
		var chosen: String = str(config_data["unit"])
		if chosen != unit:
			unit = chosen
			rebuild = true
	if config_data.has("rotation_offset"):
		var offset: float = float(config_data["rotation_offset"])
		if not is_equal_approx(offset, rotation_offset):
			rotation_offset = offset
			rebuild = true
	if config_data.has("unit_count"):
		var count: int = int(config_data["unit_count"])
		if count != unit_count:
			unit_count = count
			rebuild = true
	# Only rebuild when something actually changed AND _ready has already built
	# once — an unguarded rebuild here would re-run construction on every shipped
	# placement that passes an unrelated config key.
	if rebuild and _built and is_inside_tree():
		_build()
