extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
	museum.flush_stamps()
	await create_timer(1.0).timeout
	var gallery := find_scene("/line_relations_gallery.gd")
	check("line gallery loads",gallery!=null)
	if gallery==null:return
	var planks: Array=[]
	for line in gallery.lines:
		if str(line.name).begins_with("wall_plank_"):
			planks.append({"name":str(line.name),"length_m":line.span,"angle_degrees":rad_to_deg(asin(line.basis.x.y)),"centre":xyz(line.position)})
	observations["planks"]=planks
	check("seven planks present",planks.size()==7)
	await snapshot("seven-planks",gallery.to_global(Vector3(7.2,1.65,-1.0)),gallery.to_global(Vector3(12.1,1.65,3.5)),68)
	await snapshot("along-the-wall",gallery.to_global(Vector3(8.8,1.65,8.5)),gallery.to_global(Vector3(11.8,1.65,3.5)),72)

func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty()},"  "))
	quit(0 if failures.is_empty() else 1)
