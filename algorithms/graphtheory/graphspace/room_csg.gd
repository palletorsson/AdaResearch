# room_csg.gd
# Attach this to your Room.tscn root node
extends Node3D

@export var door_size: Vector3 = Vector3(1.6, 2.3, 0.6)  # width, height, depth of cut
@export var shell_path: NodePath = NodePath("Shell")      # your outer CSGBox3D
@export var margin_from_center: float = 4.0               # push door to wall (half the room size)

func carve_door_facing(dir: Vector3) -> void:
	var shell := get_node_or_null(shell_path)
	if shell == null: 
		print("Warning: Shell node not found at path: ", shell_path)
		return
	
	var d := dir.normalized()
	
	var cut := CSGBox3D.new()
	cut.operation = CSGShape3D.OPERATION_SUBTRACTION
	cut.size = door_size
	cut.name = "Door_Cut_%s" % [str(d).replace("(", "").replace(")", "").replace(",", "_")]
	
	# Place the cut on the wall facing 'dir'
	var pos := Vector3(d.x, 0.0, d.z) * margin_from_center
	# Lift to door height center
	pos.y = door_size.y * 0.5
	
	# Orient so local -Z faces outward (or use looking_at)
	var basis := Basis.looking_at(d, Vector3.UP)
	cut.transform = Transform3D(basis, pos)
	
	shell.add_child(cut)
	print("Carved door facing direction: ", d)
