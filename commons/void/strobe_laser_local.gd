extends "res://algorithms/color/strobe_lasers/strobe_lasers.gd"
## The old scene lacks its declared child; build it before @onready resolves.
func _enter_tree() -> void:
	if not has_node("MultiMeshInstance3D"):
		_setup_multimesh()

func _update_beams() -> void:
	if not is_instance_valid(multimesh_instance) or multimesh_instance.multimesh == null: return
	var mm: MultiMesh = multimesh_instance.multimesh
	mm.instance_count = beam_count
	var start_angle := -deg_to_rad(spread_angle_deg)*0.5
	var step := deg_to_rad(spread_angle_deg)/maxi(1,beam_count-1)
	if spread_angle_deg >= 360: step=TAU/beam_count
	for i in beam_count:
		var direction := Vector3.FORWARD.rotated(Vector3.UP,start_angle+i*step)
		# Scale the cylinder, not its world-space origin. The original order
		# accidentally placed a 15 m beam 112.5 m above the emitter.
		var basis := Basis(Quaternion(Vector3.UP,direction)).scaled(Vector3(1,beam_length,1))
		mm.set_instance_transform(i,Transform3D(basis,direction*beam_length*0.5))
