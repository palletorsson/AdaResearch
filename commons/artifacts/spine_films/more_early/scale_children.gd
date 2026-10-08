extends "res://commons/artifacts/spine_films/film_stage.gd"
const G = preload("res://commons/artifacts/spine_films/early/geometry.gd")
const SOURCE = "res://algorithms/primitives/scaleme/drink_me_room.gd"
var room_copy: Node3D
var witness_copy: Node3D
var dimension: Label3D
var factor := 4.0
var source_size := Vector2.ZERO
var witness_initial := Transform3D.IDENTITY
var parent_links: Node3D
var platform: MeshInstance3D
var outside_label:Label3D

func _build() -> void:
	title_text = "Only the children grow"
	phases = ["A SMALL OPENING", "ONE PARENT TRANSFORM", "FOUR TIMES EACH LENGTH", "THE OTHER FRAME STAYED"]
	notes = ["The Drink Me room ends in a 0.45 by 0.60 metre opening.", "The room's floor and doorway share one parent.", "The source multiplies that parent's scale by four in one cut.", "A separate 1.8 by 2.4 metre frame has not changed."]
	source_paths = [SOURCE]
	var src: Node3D = load(SOURCE).new()
	factor = src.FACTOR; source_size = Vector2(src.EXIT_WIDTH,src.EXIT_HEIGHT)
	src.room = Node3D.new(); src.add_child(src.room)
	var wall_material := G.material(Color(.52,.67,.75,.24))
	src.box(src.room,"Floor",Vector3(src.ROOM_WIDTH,.04,src.ROOM_DEPTH),Vector3(0,-.02,src.ROOM_DEPTH*.5),G.material(Color("34495b")),false)
	src.door_wall("TinyExit",src.ROOM_DEPTH,src.EXIT_WIDTH,src.EXIT_HEIGHT,wall_material,src.EXIT_X)
	# The same three frame pieces used beside TinyExit in the authored room.
	var brass:=G.material(G.GOLD)
	src.box(src.room,"DoorFrameL",Vector3(.02,src.EXIT_HEIGHT+.02,.03),Vector3(src.EXIT_X-src.EXIT_WIDTH*.5-.01,src.EXIT_HEIGHT*.5+.01,src.ROOM_DEPTH-.06),brass,false)
	src.box(src.room,"DoorFrameR",Vector3(.02,src.EXIT_HEIGHT+.02,.03),Vector3(src.EXIT_X+src.EXIT_WIDTH*.5+.01,src.EXIT_HEIGHT*.5+.01,src.ROOM_DEPTH-.06),brass,false)
	src.box(src.room,"DoorFrameTop",Vector3(src.EXIT_WIDTH+.04,.02,.03),Vector3(src.EXIT_X,src.EXIT_HEIGHT+.01,src.ROOM_DEPTH-.06),brass,false)
	# The actual source wall routine cuts the opening; this is not a painted hole.
	src.make_witness(G.material(G.GOLD))
	var container := Node3D.new(); display.add_child(container); container.scale=Vector3.ONE*.26
	container.rotation.y=PI; container.position=Vector3(0,.25,2.1)
	room_copy = Node3D.new(); container.add_child(room_copy)
	for mesh: MeshInstance3D in src.room.find_children("*","MeshInstance3D",true,false):
		var copy := G.mesh(room_copy,mesh.mesh,Color.WHITE); copy.material_override=mesh.material_override; copy.transform=mesh.transform
	witness_copy=Node3D.new(); container.add_child(witness_copy); witness_copy.transform=src.witness.transform
	for mesh: MeshInstance3D in src.witness.find_children("*","MeshInstance3D",true,false):
		var copy := G.mesh(witness_copy,mesh.mesh,G.GOLD); copy.transform=mesh.transform
	witness_initial=witness_copy.transform
	parent_links=Node3D.new();display.add_child(parent_links)
	var parent_at:=container.transform.origin
	G.sphere(parent_links,parent_at,.065,G.GOLD)
	for child:Node3D in room_copy.get_children():
		G.line(parent_links,parent_at,container.transform*child.position,G.GOLD,.012)
	G.label(parent_links,"ROOM / one parent",parent_at+Vector3(.5,.14,.12),G.GOLD,.16)
	platform=G.box(display,Vector3(0,.08,0),Vector3(5.4,.15,5.8),Color("1e3042"))
	dimension=G.label(display,"",Vector3(0,3.15,0),G.WHITE,.15)
	outside_label=G.label(display,"SAME OPENING / separate parents",Vector3(-1.25,.18,-1.70),G.GOLD,.075)
	evidence={"factor":factor,"small_exit_m":[source_size.x,source_size.y],"witness_m":[source_size.x*factor,source_size.y*factor],"source_wall_parts":src.room.get_child_count(),"method":"door_wall / make_witness; FACTOR from enlarge","presentation_scale":.26}
	src.free()
	frame_scene(Vector3(0,1.35,-.4),10.2,.68,.41)

func _draw(time: float) -> void:
	var p:=phase_index(time)
	# Preserve the actual cut; no invented physical tween through the room.
	var s:=factor if p>=2 else 1.0
	room_copy.scale=Vector3.ONE*s
	dimension.text="%.2f x %.2f m / room scale %.0f" % [source_size.x*s,source_size.y*s,s]
	witness_copy.visible=p>=2
	parent_links.visible=p==1
	platform.visible=p>=2
	outside_label.visible=p==3
	if p<2:
		dimension.position=Vector3(-.08,1.25,1.1)
		frame_scene(Vector3(-.08,.63,1.46),4.4,.55,.40)
	elif p==2:
		dimension.position=Vector3(0,3.6,0)
		frame_scene(Vector3(0,1.35,-.4),10.2,.68,.41)
	else:
		dimension.position=Vector3(-1.25,1.08,-2.00)
		dimension.text="BOTH OPENINGS / 1.8 x 2.4 m"
		frame_scene(Vector3(-1.25,.60,-2.10),2.8,-.6,.25)

func validation() -> Dictionary:
	return {"passed":is_equal_approx(factor,4.0) and source_size.is_equal_approx(Vector2(.45,.60)) and witness_copy.transform.is_equal_approx(witness_initial),"evidence":evidence}
