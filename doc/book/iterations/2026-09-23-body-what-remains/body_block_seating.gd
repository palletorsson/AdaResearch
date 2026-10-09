extends "res://tools/probes/transformation_encounters.gd"
func measure(field: Node3D) -> Array:
	var result: Array=[]
	for i in field._count:
		result.append({"factor":field._shown[i],"root_y":field.global_position.y,"local_y":field._bodies[i].position.y,"world_base":field._bodies[i].global_position.y-field._shapes[i].size.y*0.5})
	return result
func landing_checks() -> void:
	var field:=find_scene("/approach_scale.gd")
	var actor:CharacterBody3D=museum.get("_player")
	actor.set_process(false);actor.set_physics_process(false);actor.global_position=Vector3(-100,0,-100)
	await create_timer(1.5).timeout
	observations["before"]=measure(field)
	actor.global_position=field.to_global(Vector3(0.75,0,0));actor.global_position.y=0
	await create_timer(1.5).timeout
	observations["near"]=measure(field)
	actor.global_position=Vector3(-100,0,-100)
	await create_timer(2).timeout
	observations["after"]=measure(field)
	print("BLOCK_BASES ",JSON.stringify(observations))
