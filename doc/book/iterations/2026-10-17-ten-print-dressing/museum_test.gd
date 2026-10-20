extends "res://doc/book/iterations/2026-10-16-entropy-button-reach/control_probe.gd"

func cabinet_controls() -> void:
	var studio:=find_scene("/ten_print_textile/textile_studio.gd")
	check("upgraded textile studio installed in existing hall",studio!=null)
	if not studio:return
	studio.save_path=folder+"kept-cloth.json"
	# All saves in this probe stay in its isolated evidence directory.
	var wardrobe:Node=museum.get("_wardrobe")
	if wardrobe:wardrobe.appearance_save_path=folder+"appearance.cfg"
	observations["studio_origin"]=xyz(studio.global_position)
	observations["studio_scale"]=xyz(studio.scale)
	for key in studio.buttons:
		var b:Node3D=studio.buttons[key]
		var normal:Vector3=b.get_parent().global_basis.z.normalized()
		var area:Area3D=b.get_node("InteractableAreaButton")
		check(key+" cap faces visitor",b.global_basis.y.normalized().dot(normal)>.99)
		var height:=b.global_position.y-studio.global_position.y
		check(key+" at reachable height",height>=.72 and height<=1.40)
		var hit:=ray_hit(b,normal)
		check(key+" exposed to pointer",hit.get("collider")==area)
		if key in ["RIBBON","STITCH","PIXEL","PALETTE","REPEAT"]:
			var pulses:Array=[0]
			var callback:Callable=func():pulses[0]+=1
			b.pressed.connect(callback)
			probe_hand.global_position=b.to_global(Vector3(0,.045,0));await settle_input()
			check(key+" contact presses once",pulses[0]==1)
			await settle_input();check(key+" held contact does not repeat",pulses[0]==1)
			probe_hand.position=Vector3(0,-100,0);await settle_input()
			if hit.get("collider")==area:
				XRToolsPointerEvent.pressed(pointer,area,hit.position);await settle_input()
				XRToolsPointerEvent.released(pointer,area,hit.position);await settle_input()
				check(key+" ray presses once",pulses[0]==2)
			b.pressed.disconnect(callback)
	studio.act("RESET")
	await snapshot("textile-studio",studio.to_global(Vector3(-.4,1.8,-6.5)),studio.to_global(Vector3(.0,1.35,.4)),70)
	await snapshot("three-fabrics",studio.to_global(Vector3(-2.1,1.75,-3.5)),studio.to_global(Vector3(-2.1,1.55,.5)),59)
	await snapshot("dressing-room",studio.to_global(Vector3(2.2,1.7,-3.4)),studio.to_global(Vector3(3.2,1.45,.8)),65)
	# The actual museum visitor can walk in, turn and leave on the same floor.
	var walker:CharacterBody3D=museum.get("_player")
	check("museum walker available",walker!=null)
	if walker:
		museum.set("_player",null)
		walker.global_position=studio.to_global(Vector3(3.2,.08,-2.2));walker.velocity=Vector3.ZERO
		for target in [Vector3(3.2,.0,.5),Vector3(3.2,.0,-2.2)]:
			var dest:=studio.to_global(target)
			for frame in 140:
				var d:=dest-walker.global_position;d.y=0
				var v:=d.normalized()*1.5 if d.length()>.08 else Vector3.ZERO
				walker.velocity=Vector3(v.x,0 if walker.is_on_floor() else walker.velocity.y-11.0/60,v.z)
				walker.move_and_slide();await physics_frame
			check("walk dressing room "+str(target),Vector2(walker.global_position.x-dest.x,walker.global_position.z-dest.z).length()<.2 and absf(walker.global_position.y-dest.y)<.2)
	# Wear on the production desktop camera for a real mirror screenshot.
	var eye:Camera3D=museum.get("_cam")
	if eye and wardrobe:
		eye.global_position=studio.to_global(Vector3(3.2,1.7,.05))
		eye.look_at(studio.to_global(Vector3(3.2,1.3,1.62)));eye.make_current()
		check("live visitor wardrobe found",studio.wardrobe()==wardrobe)
		studio.act("WEAR")
		for i in 120:wardrobe.costume._process(1.0/60)
		studio.mirror._process(0)
		await create_timer(.5).timeout;await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder+"worn-in-mirror.png"))
		check("same fabric worn in live hall",wardrobe.suit_cloth==studio.record)
		studio.act("TAKE OFF")
	var floor_print:Node3D
	for n in hall.find_children("*","Node3D",true,false):
		if n.get_script()!=null and str(n.get_script().resource_path).ends_with("/ten_print_structure.gd") and n.form=="floor":floor_print=n
	check("large mesh floor print installed",floor_print!=null)
	if floor_print:
		check("floor print still linked to its screen",floor_print.link_state()=="linked")
		check("one cell bed per live address",floor_print.get_node("CellBeds").multimesh.instance_count==floor_print.get_dims().x*floor_print.get_dims().y)
		var cells:Dictionary=floor_print.get_cells()
		var iface:Node=floor_print.linked_interface()
		if iface:
			var field:Dictionary=iface.get_field();var match_all:=true
			for cell in cells:match_all=match_all and field.get(cell+Vector2i(0,floor_print.row_offset()))==cells[cell]
			check("every floor orientation matches actual screen",match_all)
		await snapshot("large-print-standing",floor_print.to_global(Vector3(5,1.7,5.7)),floor_print.to_global(Vector3(5,0,1.6)),80)
		await snapshot("large-print-cells",floor_print.to_global(Vector3(2.8,1.7,3.9)),floor_print.to_global(Vector3(2.8,0,2.2)),60)
	var tall_count:=0
	for n in hall.find_children("*","Node3D",true,false):
		if not is_instance_valid(n):continue
		if n.get_script()==null or not str(n.get_script().resource_path).ends_with("/tenprintantmaze/ten_print_maze.gd"):continue
		tall_count+=1
		check("tall field %d uses mesh characters"%tall_count,n.impression=="character")
		if absf(fmod(n.rotation_degrees.y,180.0)-90.0)<.1:
			check("cross-room mesh field leaves standing sightline open",n.global_position.y>=3.0)
		var glyphs_ok:=true
		for cell in n.wall_nodes:
			glyphs_ok=glyphs_ok and cell.get_child(0).mesh is BoxMesh and cell.get_child_count()==1
		check("tall field %d has 100 glyphs with batched cell frames"%tall_count,glyphs_ok and n.wall_nodes.size()==100 and n.character_frames.multimesh.instance_count==400)
		if tall_count==1:
			# Freeze only for a clear photograph, after checking its live configuration.
			var old:Array=n.maze.duplicate(true);n._on_wall_timer_timeout()
			var changed:=0
			for z in 10:
				for x in 10:
					if old[z][x]!=n.maze[z][x]:changed+=1
			check("mesh characters retain one-cell replacement",changed==1)
			n.wall_timer.stop()
			await snapshot("tall-mesh-characters",n.to_global(Vector3(7,5,5)),n.to_global(Vector3(0,5,5)),80)
	check("all three tall fields upgraded",tall_count==3)
