extends "res://doc/book/iterations/2026-10-17-primitive-encounters/probe.gd"
func line_checks() -> void:
	var mark:=find_scene("/walk_this_line_marking.gd")
	var gallery:=find_scene("/line_relations_gallery.gd")
	check("relocated floor instruction loaded",mark!=null)
	if mark==null:return
	check("floor instruction sits on supported floor",not floor_at(mark.global_position).is_empty())
	var below:=floor_at(mark.global_position)
	check("floor instruction is not suspended at old glass height",not below.is_empty() and absf(below.position.y-mark.global_position.y)<0.05)
	await snapshot("floor-instruction",mark.to_global(Vector3(2,2,-2)),mark.global_position,60)
	if gallery!=null:await snapshot("line-gallery",gallery.global_position+Vector3(-8,5,-6),gallery.global_position+Vector3(0,1,0),65)
