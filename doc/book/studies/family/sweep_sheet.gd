extends Node3D
## Supplied: the sweep sheet. One contract: hang(member, title).
## hang() stands `member` next in the row, on the ground, `spacing` metres from
## the one before, and writes `title` on a plate at its feet. A member with no
## material of its own gets the sheet's one paint, so that all are seen in the
## same colour. That is all: the sheet does not build a member, set it or
## count it. What stands on the sheet is what the sheet was handed.

@export var spacing := 1.2      # metres from one member's middle to the next
@export var paint: Material     # the one material for members that bring none

var hung: Array[Node3D] = []    # the members, in the order they were hung
var plates: Array[Label3D] = [] # one plate for each

func hang(member: Node3D, title: String) -> void:
	if not member.is_inside_tree():
		add_child(member)       # a member nobody has put in the room yet stands with the sheet
	var foot := 0.0             # how far the member reaches below its own middle
	if member is MeshInstance3D and member.mesh != null:
		foot = -member.get_aabb().position.y
		if member.material_override == null and paint != null:
			member.material_override = paint
	var slot := Vector3(hung.size() * spacing, 0.0, 0.0)
	member.global_position = to_global(slot + Vector3(0.0, foot, 0.0))
	var plate := Label3D.new()
	plate.text = title
	plate.font_size = 64
	plate.pixel_size = 0.004
	plate.modulate = Color(0.94, 0.92, 0.88)
	plate.rotation.x = -PI / 2.0    # flat on the ground, its top away from us
	add_child(plate)
	plate.position = slot + Vector3(0.0, 0.02, 0.8)
	hung.append(member)
	plates.append(plate)
