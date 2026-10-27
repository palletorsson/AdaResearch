extends RefCounted
## Void-only fittings for the existing comparisons. Counts, recipes, door rules,
## heat model and chair physics remain owned by the original museum scripts.
const Mount=preload("res://commons/void/ceiling_display_mount.gd")
const Hardware=preload("res://commons/void/randomness_interface_hardware.gd")
const Supply=preload("res://commons/void/hardware_supply.gd")
const Objects=preload("res://commons/artifacts/ordinary_entropies/objects.gd")

static func attach(source: Node3D, kind: String) -> void:
	if source.has_meta("entropies_staged"):return
	source.set_meta("entropies_staged",true)
	if kind == "entropy_door_dynamics" and source.has_method("finish_installation"):
		source.finish_installation()
		return
	match kind:
		"entropy_chairs_shannon", "entropy_chairs_boltzmann":
			source.wall_text.position=Vector3(-3.65,1.42,0)
			source.wall_text.rotation_degrees.y=90
		"entropy_chairs_description":
			source.wall_text.position=Vector3(-6.75,1.42,0)
		"entropy_door_dynamics":
			# Only the two blind ends shorten. The three full-size doorways and
			# their leaf swings retain their original geometry and behaviours.
			var old: Node3D=source.get_node("DoorWall")
			source.remove_child(old);old.free()
			var wall:=Node3D.new();wall.name="DoorWall";source.add_child(wall)
			for ends in [Vector2(-6.8,-5.73),Vector2(-3.27,-1.23),Vector2(1.23,3.27),Vector2(5.73,6.8)]:
				Objects.box(wall,Vector3((ends.x+ends.y)/2,1.165,0),Vector3(ends.y-ends.x,2.33,.24),Color("e3dfd2"),true)
			Objects.box(wall,Vector3(0,2.49,0),Vector3(13.6,.32,.24),Color("e3dfd2"),true)
			var face: Node3D=source.get_node("SharedDoorControls")
			case_controls(face,Vector2(1.6,.36),false)
		"entropy_cooling_cup":
			source.wall_text.position=Vector3(0,1.65,-.90)
			source.wall_text.rotation_degrees.y=0
		"entropy_frosted_chair":
			source.wall_text.position=Vector3(6.75,1.42,0)
		"entropy_ball_pit":
			# Four original full-size pyramids, closer together in the east wing.
			# Preserve the children themselves so each control keeps its callbacks.
			for i in source.versions.size():
				var group: Node3D=source.versions[i]
				group.position=Vector3(-1.85 if i%2==0 else 1.85,0,3.3 if i<2 else -3.3)
				var face: Node3D=group.get_node("TableControlStrip")
				face.position.y=1.05;face.rotation_degrees.x=-35
				# Retire the old thin table legs; the controls now hang from a yoke.
				for child in group.get_children():
					if child is MeshInstance3D and child.mesh is BoxMesh and child.mesh.size.is_equal_approx(Vector3(.035,.86,.035)):
						child.queue_free()
				case_controls(face,Vector2(2.8,.60),true)
			source.wall_text.position=Vector3(0,1.42,-6.1)
			source.wall_text.rotation_degrees.y=0
	if "wall_text" in source and is_instance_valid(source.wall_text):
		mount_reading(source.wall_text)
	# Moving a parent of an active RigidBody does not reliably update Jolt's
	# cached transform. Flush the same bodies into their new staging positions.
	for body in source.find_children("*","RigidBody3D",true,false):
		PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,body.global_transform)
		body.linear_velocity=Vector3.ZERO;body.angular_velocity=Vector3.ZERO

static func mount_reading(panel: Node3D) -> void:
	# Keep the original live text nodes. Remove just their freestanding backing.
	for child in panel.get_children():
		if child is StaticBody3D:
			panel.remove_child(child);child.free()
		elif child is MeshInstance3D and child.mesh is BoxMesh:
			var size: Vector3=child.mesh.size
			if size.y>2 or size.x>1.9:
				panel.remove_child(child);child.free()
			elif size.x<.1 or size.y<.1:child.material_override=Mount.material("343b3d",.85)
	panel.set_meta("independent_instrument",true)
	Hardware.attach(panel,{"title":"ENTROPIES / COMPARE","action":"SAME OBJECTS / DIFFERENT QUESTION","clearance":0,"accent":"#ed83b5"})
	# Reading light aimed down the face, not a floor-filling work lamp.
	var light:=OmniLight3D.new();light.name="ReadingLight"
	light.position=Vector3(0,.45,.30);light.light_color=Color("ffebda")
	light.light_energy=.55;light.omni_range=2.8;light.shadow_enabled=false
	panel.add_child(light)

static func case_controls(face: Node3D, size: Vector2, suspended: bool) -> void:
	var case:=Node3D.new();case.name="ControlHardware";face.add_child(case)
	Mount.box(case,"IvoryCase",Vector3(0,0,-.055),Vector3(size.x+.12,size.y+.12,.10),Mount.material("e8e4d8",.92))
	Mount.box(case,"GraphiteLip",Vector3(0,-size.y/2-.045,0),Vector3(size.x+.16,.035,.13),Mount.material("343b3d",.85))
	for side in [-1,1]:
		Mount.box(case,"CaptiveRail",Vector3(side*(size.x/2+.035),0,.005),Vector3(.04,size.y+.10,.14),Mount.material("343b3d",.85))
	for button in face.find_children("*","Node3D",true,false):
		if "released_color" in button:
			button.released_color=Color("ed83b5") if button.released_color.g>.6 and button.released_color.r<.7 else button.released_color
	# The structure follows world-up even though the console is tilted.
	var carrier:=Node3D.new();carrier.name="MountedControlSupply";face.get_parent().add_child(carrier)
	carrier.global_position=face.to_global(Vector3(0,0,-.14))
	var floor_root:=Hardware._floor(face)
	var top:=Hardware._slab_y(floor_root)-carrier.global_position.y
	if suspended:
		var steel:=Mount.material("343b3d",.8,.15)
		for x in [-size.x*.42,size.x*.42]:
			Mount.box(carrier,"DropMast",Vector3(x,top/2,0),Vector3(.055,top,.075),steel)
			Mount.box(carrier,"AnchorPlate",Vector3(x,top-.035,0),Vector3(.35,.07,.30),steel)
			var mark:=Marker3D.new();mark.name="SlabContact";mark.position=Vector3(x,top,0);carrier.add_child(mark)
		Mount.box(carrier,"Yoke",Vector3.ZERO,Vector3(size.x,.07,.10),Mount.material("e8e4d8",.9))
	else:
		Mount.box(carrier,"WallCleat",Vector3(0,0,-.06),Vector3(size.x,.12,.14),Mount.material("343b3d",.8))
	Supply.connect_unit(carrier,Vector3.ZERO)
