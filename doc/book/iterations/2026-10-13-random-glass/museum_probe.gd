extends "res://doc/book/iterations/2026-10-13-four-by-four-seed/museum_probe.gd"

func landing_checks() -> void:
	museum.call("flush_stamps")
	await create_timer(0.3).timeout
	var initial:=find_scene("/seed_replay_demo.gd")
	var opening: Dictionary=initial.capture_museum_state() if initial!=null else {}
	await super.landing_checks()
	var demo:=find_scene("/seed_replay_demo.gd")
	if demo==null:return
	demo.restore_museum_state(opening)
	await create_timer(0.4).timeout
	check("Random Definition opts into glass",demo.surface=="glass")
	check("preview retains the opening seed provenance",demo.capture_museum_state().source_receipt==opening.source_receipt)
	check("each comparison grid has sixteen glass panes",demo._columns[0].cubes.size()==16 and demo._columns[1].cubes.size()==16)
	var pane: MeshInstance3D=demo._columns[0].cubes[0]
	var mat: StandardMaterial3D=pane.material_override
	check("thin double-sided panes use transparent material",pane.mesh is QuadMesh and mat.transparency==BaseMaterial3D.TRANSPARENCY_ALPHA and mat.cull_mode==BaseMaterial3D.CULL_DISABLED)
	check("fixed texture supplies translucent alpha",mat.albedo_texture.get_image().get_pixel(0,0).a>0.1 and mat.albedo_texture.get_image().get_pixel(0,0).a<0.8)
	var clear_back:=true
	for node in demo._number_display.get_children():
		if node is MeshInstance3D and node.mesh is BoxMesh and node.mesh.size.y>1.0:clear_back=false
	check("opaque backing has been removed from both windows",clear_back)
	var held: PackedColorArray=demo.column_colors(0)
	var generator:=RandomNumberGenerator.new()
	generator.seed=435
	var expected:=PackedColorArray()
	for i in range(16):expected.append(Color(generator.randf(),generator.randf(),generator.randf()))
	check("glass retains exact RGB draws without extra sampling",held==expected and demo._rng.state==generator.state)
	var standing:=demo.to_global(Vector3(0,1.0,1.6))
	check("window approach retains solid floor",not floor_at(standing-Vector3.UP).is_empty())
	var frame_id: int=demo._window_frames.get_instance_id()
	demo.set_grid_side(8)
	await tick()
	check("matrix rebuild replaces its frame and retains glass",demo._window_frames.get_instance_id()!=frame_id and demo._columns[0].cubes[0].mesh is QuadMesh)
	demo.set_grid_side(4)
	await tick()
	check("return to four retains the same colours",demo.column_colors(0)==held and demo.column_colors(1)==held)
	await snapshot("windows",demo.to_global(Vector3(-0.5,1.95,3.4)),demo.to_global(Vector3(0,1.80,0)),56)
	await snapshot("hall",demo.to_global(Vector3(-1.9,2.0,5.8)),demo.to_global(Vector3(-0.3,2.3,0)),61)
	await snapshot("glass-close",demo.to_global(Vector3(-0.88,1.8,1.2)),demo.to_global(Vector3(-0.67,1.8,0)),62)
	demo.toggle_extra_draw()
	check("discard changes only the right glass colours",demo.column_colors(0)==held and demo.column_colors(1)!=held)
	await snapshot("extra-draw",demo.to_global(Vector3(-0.5,1.95,3.4)),demo.to_global(Vector3(0,1.80,0)),56)
	demo.toggle_extra_draw()
	var ordinary: Node3D=load("res://algorithms/randomness/seed_replay/seed_replay_demo.tscn").instantiate()
	root.add_child(ordinary)
	check("other placements keep the original solid cubes",ordinary.surface=="solid" and ordinary._columns[0].cubes[0].mesh is BoxMesh)
	ordinary.queue_free()
	observations["scope"]="Actual museum, preserved seeded RGB and draw order, live matrix slider, clear-backed alpha panes. Desktop captures; no physical headset check. Glass does not simulate spectral refraction or coloured shadow transmission."
