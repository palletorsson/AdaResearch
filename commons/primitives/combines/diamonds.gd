# DiamondTower.gd
extends Node3D

# @identity
# essence: diamonds[i].rotation_y = rotation_offset * i — a tower of octahedra each rotated by an accumulating angle
# desire: learner sees how repetition with incremental rotation creates emergent spiral form from simple rule
# critical_parameter: rotation_offset — the per-instance rotation delta; at 0° it is a boring stack, at 15° a helix
# triggers: nothing at runtime — the pattern is baked into instance transforms at ready()
# emerges: the helix as a consequence of uniform angular accumulation — not designed, derived
# needs: [missing VR controls — static; would benefit from live rotation_offset slider]
# relationships: uses octahedron as its unit; sibling to combine_portals in the combines category
# truth: complex regular patterns emerge from simple repeated rules — the rule is more fundamental than the result

@export var unit_count := 12
@export var unit_size := 2.5
@export var unit_height := 2.0
@export var rotation_offset := 15.0 # degrees per step twist

func _ready() -> void:

	# stack alternating "diamonds" using octahedron scene
	for i in range(unit_count):
		var diamond_scene = preload("res://commons/primitives/octahedron/octahedron.tscn")
		var diamond := diamond_scene.instantiate()
		diamond.position = Vector3(0, unit_height * i + unit_height, 0)
		diamond.rotation.y = deg_to_rad(rotation_offset * i)
		diamond.scale = Vector3(unit_size, unit_height, unit_size)
		add_child(diamond)
