extends "res://doc/book/iterations/2026-10-16-tutorial-shelf-in-hall/museum_probe.gd"
## Repeat the existing seed/record checks through their APIs; NEXT alone is public.

func press(shelf: Node, word: String) -> void:
	match word:
		"NEXT": super.press(shelf, word)
		"REPLAY": shelf.replay()
		"KEEP": shelf.get_node("Notebook").save_trial()
		"LOAD": shelf.get_node("Notebook").load_trial()

func finish() -> void:
	if hall != null:
		var shelf := find_scene("randomness_tutorial_shelf.gd")
		if shelf != null:
			var controls: Node3D = shelf.get_node("Controls")
			var extension: MeshInstance3D = controls.get_node("TableExtension")
			var button: Node3D = controls.get_node("NEXT")
			check("one button on a joined extension",controls.get_child_count()==2 and not controls.has_node("KEEP") and not controls.has_node("REPLAY") and not controls.has_node("LOAD"))
			check("extension meets the front edge at tabletop height",is_equal_approx(extension.position.y,1.16) and extension.position.z-extension.mesh.size.z/2<0.36 and extension.position.z+extension.mesh.size.z/2>0.36)
			check("NEXT faces upwards from tabletop",button.basis.y.is_equal_approx(Vector3.UP) and is_equal_approx(button.position.y,1.19))
			var body: StaticBody3D = extension.get_child(0)
			check("extension has matching physical surface",body.collision_layer==1 and body.get_child(0).shape.size==extension.mesh.size)
			check("caption belongs to the moving button cap",button.get_node("Button/Caption").text=="NEXT")
			observations["control_scope"]="One physical NEXT button. Replay/save/load checks call the retained helper API, not removed controls. Standalone tutorial still has its research controls."
	super.finish()
