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
	var shifted := eye+Vector3(0.8,0,0)
	var projection_normal: Vector3=(edges[0]-shifted).cross(edges[1]-shifted).normalized()
	var separation_degrees: Array=[]
	for i in range(2):
		agreement=agreement and (edges[i]-eye).normalized().dot((line[i]-eye).normalized())>0.99999
		# Measure distance from the projected edge line, not distance between endpoints.
		var deviation := rad_to_deg(asin(absf((line[i]-shifted).normalized().dot(projection_normal))))
		separation_degrees.append(deviation)
		separates=separates and deviation>0.6
	check("entrance eye aligns the separate line with the ceiling edge",agreement)
	check("a sideways step separates the two projections",separates)
	for height in [1.05,2.0]:
		var edge_to_eye: Vector3=eye-edges[0]
		var x: float=edges[0].x+(height-edges[0].y)*edge_to_eye.x/edge_to_eye.y
		var other_eye := Vector3(x,height,eye.z)
		var normal: Vector3=(edges[0]-other_eye).cross(edges[1]-other_eye).normalized()
		check("alignment available at eye height "+str(height),absf((line[0]-other_eye).normalized().dot(normal))<0.00001 and x>=-5.5 and x<=-2.5)
	var walker:=CharacterBody3D.new();walker.collision_layer=0;walker.collision_mask=1
	var shape:=CollisionShape3D.new();var capsule:=CapsuleShape3D.new()
	capsule.radius=0.3;capsule.height=1.6;shape.shape=capsule;shape.position.y=0.8
	walker.add_child(shape);root.add_child(walker)
	walker.global_position=gallery.to_global(Vector3(-5.5,0.025,-7))
	await physics_frame
	check("whole lateral viewing strip is physically clear",walker.move_and_collide(Vector3(3,0,0))==null)
	walker.queue_free()
	observations["separation_degrees"]=separation_degrees
	observations["eye"]=xyz(eye);observations["suspended_height_m"]=line[0].y
	await snapshot("entering-perspective",gallery.to_global(eye),gallery.to_global(Vector3(-2,2.4,10)),76)
	await snapshot("ceiling-aligned",gallery.to_global(eye),gallery.to_global(Vector3(-9.8,4.2,3.5)),52)
	await snapshot("ceiling-apart",gallery.to_global(eye+Vector3(0.8,0,0)),gallery.to_global(Vector3(-9.8,4.2,3.5)),52)
	await snapshot("under-the-line",gallery.to_global(Vector3(-3.2,1.65,-2.5)),gallery.to_global(Vector3(-7,2.7,-0.5)),62)

func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Native museum render and projection check; no headset acceptance."},"  "))
	quit(0 if failures.is_empty() else 1)
