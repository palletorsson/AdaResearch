extends "res://tools/probes/transformation_encounters.gd"
func landing_checks() -> void:
	root.size=Vector2i(1600,1050);museum.call("flush_stamps");await create_timer(0.5).timeout
	var jars:=find_scene("/ordinary_entropies/jar_states.gd")
	var ruin:=find_scene("/randomness_space/entropy_ruin.gd")
	check("both installations present",jars!=null and ruin!=null)
	if jars==null or ruin==null:return
	jars.set_process(false);jars.restart();ruin.running=false
	await snapshot("jars-before",jars.to_global(Vector3(0,1.8,4.7)),jars.to_global(Vector3(0,1.3,0)),65)
	await snapshot("ruin-before",ruin.to_global(Vector3(-0.8,2.5,-6)),ruin.to_global(Vector3(0,1.6,0)),65)
	await snapshot("column-before",ruin.to_global(Vector3(-2.0,1.8,-1.9)),ruin.to_global(Vector3(-0.8,1.7,-0.1)),53)
	var arrays: Array=ruin._drum(0.3,0.31,0).surface_get_arrays(0)
	var p: Vector3=arrays[Mesh.ARRAY_VERTEX][0];var n: Vector3=arrays[Mesh.ARRAY_NORMAL][0]
	observations.drum_side_normal_radial_dot=n.dot(Vector3(p.x,0,p.z).normalized())
