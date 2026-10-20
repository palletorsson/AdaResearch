extends "res://commons/testing/probe_entropy_ruin.gd"
func run() -> void:
	var jars=load("res://commons/artifacts/ordinary_entropies/jar_states.gd").new();root.add_child(jars);jars.set_process(false)
	check("shared plinth with solid support",jars.has_node("Plinth") and jars.get_node("Plinth").mesh.size==Vector3(5.8,0.32,1.55))
	var record: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://doc/book/iterations/2026-10-16-slow-lavender-columns/verification.json"))
	jars.restart();jars.advance(188)
	for i in 4:
		var jar: Node3D=jars.jars[i]
		var contained:=true;var unchanged:=true;var list: Array=jar.positions()
		for j in 80:
			var p: Vector3=jar.display_beads[j].position
			contained=contained and Vector2(p.x,p.z).length()+jar.BEAD_RADIUS<jar.COLUMN_RADIUS and p.y-jar.BEAD_RADIUS>=jar.COLUMN_BOTTOM and p.y+jar.BEAD_RADIUS<=jar.COLUMN_BOTTOM+jar.COLUMN_HEIGHT
			var old: Array=record.samples[-1].columns[i].positions[j]
			unchanged=unchanged and list[j].is_equal_approx(Vector3(old[0],old[1],old[2]))
		check("larger round beads contained / "+str(i),contained)
		check("slow paths retained / "+str(i),unchanged)
		check("wider taller glass / "+str(i),jar.COLUMN_RADIUS==0.52 and jar.COLUMN_HEIGHT==2.3)
		var arrays: Array=jar.jar_shell().surface_get_arrays(0);var winding:=true
		for t in range(0,arrays[Mesh.ARRAY_VERTEX].size(),3):
			var a: Vector3=arrays[Mesh.ARRAY_VERTEX][t];var b: Vector3=arrays[Mesh.ARRAY_VERTEX][t+1];var c: Vector3=arrays[Mesh.ARRAY_VERTEX][t+2]
			var n: Vector3=arrays[Mesh.ARRAY_NORMAL][t]
			winding=winding and -(b-a).cross(c-a).normalized().dot(n)>0.5
		check("glass clockwise faces agree with outward normals / "+str(i),winding)
	jars.free()
	await verify_ruin()
	report_path="res://doc/book/iterations/2026-10-16-plinth-and-physical-ruin/verification.json"
	finish()
