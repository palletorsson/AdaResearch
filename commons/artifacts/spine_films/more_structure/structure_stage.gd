extends "res://commons/artifacts/spine_films/late/late_stage.gd"
func validation()->Dictionary:
	var result:Dictionary=super.validation()
	var checks:Dictionary={"four_phases":phases.size()==4,"sources_exist":not source_paths.is_empty()}
	for path in source_paths:checks["exists "+path]=ResourceLoader.exists(path)
	match name:
		"ca_triplet":
			checks["actual_rule90_table"]=evidence.get("truth_table",[])==[false,true,false,true,true,false,true,false]
			checks["history"]=evidence.get("rows",[]).size()==13
		"cantor_thirds":
			checks["recursive_counts"]=evidence.get("counts",[])==[1,2,4,8,16,32]
			checks["retained_length"]=absf(evidence.get("lengths",[99])[-1]-5.4*pow(2.0/3.0,5))<.0001
		"jelly_skin":
			checks["six_faces"]=evidence.get("faces",0)==6
			checks["sampled_skin"]=evidence.get("vertices",0)==216 and evidence.get("triangles",0)==300
			checks["crown_pin"]=evidence.get("actual_pin",false)
		"metaball_sum":
			checks["21_surfaces"]=evidence.get("mesh_samples",0)==21
			checks["sum_before_extraction"]=evidence.get("sum_error",99.0)<.0001
			checks["all_meshes_have_triangles"]=evidence.has("triangle_counts") and evidence.triangle_counts.min()>0
		"boolean_overlap":
			checks["four_offsets"]=evidence.get("offsets",[]).size()==4
			checks["native_intersection"]=evidence.get("native_operation",-1)==CSGShape3D.OPERATION_INTERSECTION
		"spanning_choice":
			checks["tree_edges"]=evidence.get("accepted",0)==evidence.get("vertices",0)-1
			checks["source_edges_match"]=evidence.get("accepted_keys",[])==evidence.get("source_keys",[0])
			checks["source_cost_matches"]=absf(evidence.get("observer_cost",99.0)-evidence.get("source_cost",0.0))<.0001
	result["checks"]=checks;result["passed"]=not checks.values().has(false)
	return result
