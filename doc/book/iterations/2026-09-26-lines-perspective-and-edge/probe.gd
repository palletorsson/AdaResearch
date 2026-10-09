extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
	museum.flush_stamps()
	await create_timer(1.0).timeout
	var gallery := find_scene("/line_relations_gallery.gd")
	check("gallery loads with all 27 movable bodies",gallery!=null and gallery.lines.size()==27)
	if gallery==null:return
	var eye: Vector3=gallery.get_meta("alignment_eye")
	var edges: Array=gallery.get_meta("alignment_edge")
	var line: Array=gallery.get_meta("alignment_line")
	var agreement := true
	var separates := true
	var shifted := eye+Vector3(2,0,0)
	var projection_normal: Vector3=(edges[0]-shifted).cross(edges[1]-shifted).normalized()
	var separation_degrees: Array=[]
	for i in range(2):
		agreement=agreement and (edges[i]-eye).normalized().dot((line[i]-eye).normalized())>0.99999
		# Measure distance from the projected edge line, not distance between endpoints.
		var deviation := rad_to_deg(asin(absf((line[i]-shifted).normalized().dot(projection_normal))))
		separation_degrees.append(deviation)
		separates=separates and deviation>0.5
	check("entrance eye aligns the separate line with the ceiling edge",agreement)
	check("a sideways step separates the two projections",separates)
	observations["separation_degrees"]=separation_degrees
	observations["eye"]=xyz(eye);observations["suspended_height_m"]=line[0].y
	await snapshot("entering-perspective",gallery.to_global(eye),gallery.to_global(Vector3(-0.5,2.4,10)),85)
	await snapshot("ceiling-aligned",gallery.to_global(eye),gallery.to_global(Vector3(-12.08,4.3,3.5)),52)
	await snapshot("ceiling-apart",gallery.to_global(eye+Vector3(2,0,0)),gallery.to_global(Vector3(-12.08,4.3,3.5)),52)

func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Native museum render and projection check; no headset acceptance."},"  "))
	quit(0 if failures.is_empty() else 1)
